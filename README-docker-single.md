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
# Start container
docker compose -f docker-compose-single.yml up -d

# Kiểm tra container đang chạy
docker ps

# Xem logs để đảm bảo MongoDB đã start thành công
docker compose logs -f mongodb-rpi
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
docker exec -i dqcai-mongorep mongorestore --username admin --password your-strong-password --authenticationDatabase admin --db myapp /data/backup/myapp
```

## 7. Monitoring và Maintenance

```bash
# Xem resource usage
docker stats dqcai-mongorep

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

