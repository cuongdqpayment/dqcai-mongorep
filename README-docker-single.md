## 1. Chuẩn bị file Docker

Tạo thư mục project và các file cần thiết:

```bash
mkdir dqcai-mongorep
cd dqcai-mongorep

# Tạo thư mục cho init scripts
mkdir init-scripts

# Copy file init-mongo.js vào thư mục init-scripts
# (Bạn copy nội dung script trên vào file init-scripts/init-mongo.js)
```

## 2. Khởi chạy MongoDB Container

```bash
# shut down container
docker compose -f docker-compose-single.yml down -v
docker compose -f docker-compose-single-with-express.yml down -v

# Start container
docker compose -f docker-compose-single.yml up -d
docker compose -f docker-compose-single-with-express.yml up -d

# Kiểm tra container đang chạy
docker ps

# Xem logs để đảm bảo MongoDB đã start thành công
docker logs mongodb-rpi --tail 10

```

## 3. Kết nối và quản lý MongoDB

### Kết nối vào MongoDB Shell:

```bash
# Kết nối với user admin
docker exec -it mongodb-rpi mongosh -u admin -p admin123 --authenticationDatabase admin

# Hoặc kết nối với user app
docker exec -it mongodb-rpi mongosh -u appuser -p app-password --authenticationDatabase myapp
```

### Các lệnh quản lý cơ bản:

```javascript
// Xem danh sách databases
show dbs

// Chuyển sang database myapp
use myapp

// Xem danh sách collections
show collections

// Xem dữ liệu trong collection
db.users.find().pretty()
db.products.find().pretty()

// Đếm số document
db.users.countDocuments()
```

## 4. Tạo thêm User và Database

```javascript
// Kết nối với admin user trước
use admin

// Tạo database mới
use newdatabase

// Tạo user mới cho database này
db.createUser({
  user: "newuser",
  pwd: "newpassword",
  roles: [
    { role: "readWrite", db: "newdatabase" },
    { role: "dbAdmin", db: "newdatabase" }
  ]
})
```

## 5. Tạo Collection với Schema Validation

```javascript
use myapp

// Tạo collection với validation rules
db.createCollection("categories", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["name", "createdAt"],
      properties: {
        name: {
          bsonType: "string",
          minLength: 1,
          maxLength: 100
        },
        description: {
          bsonType: "string",
          maxLength: 500
        },
        parentId: {
          bsonType: "objectId"
        },
        isActive: {
          bsonType: "bool"
        },
        createdAt: {
          bsonType: "date"
        }
      }
    }
  }
})

// Tạo index
db.categories.createIndex({ "name": 1 }, { unique: true })
```

## 6. Backup và Restore

```bash
# Backup database
docker exec dqcai-mongorep mongodump --username admin --password your-strong-password --authenticationDatabase admin --db myapp --out /data/backup

# Copy backup ra host
docker cp dqcai-mongorep:/data/backup ./backup

# Restore database
docker exec -i mongodb-rpi mongorestore --username admin --password admin123 --authenticationDatabase admin --db myapp /data/backup/myapp
```

## 7. Monitoring và Maintenance

```bash
# Xem resource usage
docker stats mongodb-rpi

# Xem logs real-time
docker compose logs -f

# Restart container
docker compose restart

# Stop và remove
docker compose down

# Stop và remove với volumes (⚠️ Xóa hết data)
docker compose down -v
```

## Lưu ý quan trọng:

1. **Thay đổi password**: Đổi `your-strong-password` và `app-password` thành password mạnh
2. **Firewall**: Chỉ mở port 27017 cho các IP cần thiết
3. **Backup định kỳ**: Thiết lập backup tự động
4. **ARM architecture**: MongoDB 7.0 support ARM64, phù hợp với Raspberry Pi 4


## 1. Khởi động lại với Mongo Express

```bash
# Stop container hiện tại
docker-compose down

# Start lại với Mongo Express
docker-compose up -d

# Kiểm tra cả 2 container đang chạy
docker ps
```

## 2. Truy cập Mongo Express

Mở trình duyệt và vào:
- **URL:** `http://localhost:8081` (hoặc `http://IP_raspberry:8081`)
- **Username:** `webadmin`
- **Password:** `webpass123`

## 3. Sử dụng Mongo Express

### Giao diện chính:
- **Databases:** Xem tất cả databases (admin, config, local, myapp)
- **Collections:** Click vào database để xem collections
- **Documents:** Click vào collection để xem/edit documents

### Các tính năng chính:
1. **View Documents:** Xem dữ liệu dạng JSON
2. **Add Document:** Thêm document mới
3. **Edit/Delete:** Sửa/xóa documents
4. **Import/Export:** Import JSON/CSV
5. **Indexes:** Quản lý indexes
6. **GridFS:** Quản lý files

## 4. Thao tác cơ bản qua Web UI

### Thêm document mới:
1. Vào database `myapp` → collection `users`
2. Click **"New Document"**
3. Nhập JSON:
```json
{
  "username": "web_user",
  "email": "web@example.com",
  "fullName": "Web User",
  "createdAt": {"$date": "2025-09-15T10:00:00.000Z"},
  "updatedAt": {"$date": "2025-09-15T10:00:00.000Z"}
}
```

### Query documents:
1. Vào collection
2. Sử dụng filter box:
```json
{"category": "Electronics"}
```

## 5. Bảo mật nâng cao## 6. Cấu hình nâng cao cho Docker Compose

Nếu muốn bảo mật hơn, cập nhật environment của Mongo Express:

```yaml
# Thêm vào phần environment của mongo-express
ME_CONFIG_OPTIONS_EDITORTHEME: "ambiance"  # Theme đẹp hơn
ME_CONFIG_REQUEST_SIZE: "100kb"
ME_CONFIG_SESSION_SECRET: "your-secret-key-here"
ME_CONFIG_MONGODB_ENABLE_ADMIN: "true"
ME_CONFIG_MONGODB_AUTH_DATABASE: "admin"
```

## 7. Backup qua Mongo Express

1. Vào collection muốn backup
2. Click **"Export Collection"**
3. Chọn format: JSON/CSV
4. Download file

## 8. Import dữ liệu

1. Vào collection
2. Click **"Import"** 
3. Chọn file JSON/CSV
4. Map các fields
5. Import

## 9. Monitoring qua Web

Mongo Express cung cấp:
- **Database Stats:** Kích thước database, số collections
- **Collection Stats:** Số documents, indexes
- **Server Info:** Version MongoDB, uptime
- **Connection Status:** Số connections hiện tại

## 10. Troubleshooting

### Lỗi không connect được:
```bash
# Kiểm tra logs
docker logs mongo-express-rpi

# Kiểm tra network
docker network ls
docker network inspect mongodb-rpi_mongodb-network
```

### Lỗi authentication:
```bash
# Kiểm tra user MongoDB
docker exec -it mongodb-rpi mongosh -u admin -p your-strong-password --authenticationDatabase admin
db.runCommand({usersInfo: 1})
```

### Thay đổi port Mongo Express:
```yaml
ports:
  - "9000:8081"  # Chạy trên port 9000
```

## 11. Performance Tips

- **Giới hạn kết quả:** Mongo Express tự động limit 20 documents
- **Indexes:** Sử dụng tab "Indexes" để tối ưu queries
- **GridFS:** Cho files lớn, sử dụng GridFS thay vì binary trong documents
