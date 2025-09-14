# MongoDB Replica Set trên Raspberry Pi 5

Hướng dẫn thiết lập MongoDB replica set với 3 node trên Raspberry Pi 5 sử dụng Docker.

## Yêu cầu hệ thống

- Raspberry Pi 5 với ít nhất 4GB RAM
- Docker và Docker Compose đã được cài đặt
- Ít nhất 10GB dung lượng trống

## Cài đặt Docker trên Raspberry Pi 5

```bash
# Cập nhật hệ thống
sudo apt update && sudo apt upgrade -y

# Cài đặt Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Cài đặt Docker Compose
sudo apt install docker-compose-plugin -y

# Khởi động lại để áp dụng quyền
sudo reboot
```

## Cấu trúc thư mục

```
dqcai-mongorep/
├── docker-compose.yml
├── .env
├── setup-dqcai-mongorep.sh
├── init-replica.js
├── scripts/
└── data/
    ├── mongo1/
    ├── mongo2/
    └── mongo3/
```

## Hướng dẫn sử dụng

### 1. Tạo thư mục và copy files

```bash
mkdir dqcai-mongorep
cd dqcai-mongorep

# Copy tất cả các files từ artifacts vào thư mục này
```

### 2. Cấp quyền thực thi cho script

```bash
chmod +x setup-dqcai-mongorep.sh
```

### 3. Khởi tạo replica set (một lệnh duy nhất)

```bash
./setup-dqcai-mongorep.sh setup
```

### 4. Kiểm tra trạng thái

```bash
./setup-dqcai-mongorep.sh status
```

## Các lệnh quản lý

```bash
# Khởi động containers
./setup-dqcai-mongorep.sh start

# Dừng containers
./setup-dqcai-mongorep.sh stop

# Xem logs
./setup-dqcai-mongorep.sh logs

# Xem logs của container cụ thể
./setup-dqcai-mongorep.sh logs mongo1

# Tạo backup
./setup-dqcai-mongorep.sh backup

# Restore từ backup
./setup-dqcai-mongorep.sh restore backup_20241201_120000

# Xóa tất cả dữ liệu (cẩn thận!)
./setup-dqcai-mongorep.sh clean
```

## Kết nối đến MongoDB

### Từ ứng dụng

```javascript
// Connection string cho replica set
const uri = "mongodb://admin:password123@localhost:27017,localhost:27018,localhost:27019/mydb?replicaSet=rs0&authSource=admin";

// Node.js với MongoDB driver
const { MongoClient } = require('mongodb');
const client = new MongoClient(uri);
```

### Từ MongoDB Shell

```bash
# Kết nối đến primary
docker exec -it mongo1 mongosh --host localhost --port 27017 -u admin -p password123 --authenticationDatabase admin

# Hoặc từ host
mongosh "mongodb://admin:password123@localhost:27017,localhost:27018,localhost:27019/admin?replicaSet=rs0"
```

### Mongo Express Web UI

Truy cập: http://localhost:8081
- Username: admin
- Password: webpass123

## Cấu hình nâng cao

### Thay đổi memory limits

Chỉnh sửa file `.env`:

```bash
# Cho Raspberry Pi 5 với 4GB RAM
MONGO_MEMORY_LIMIT=1g
MONGO_EXPRESS_MEMORY_LIMIT=256m

# Cho Raspberry Pi 5 với 8GB RAM
MONGO_MEMORY_LIMIT=2g
MONGO_EXPRESS_MEMORY_LIMIT=512m
```

### Thay đổi ports

Chỉnh sửa file `.env` nếu cần thiết:

```bash
MONGO1_PORT=27017
MONGO2_PORT=27018
MONGO3_PORT=27019
```

### Custom MongoDB configuration

Tạo file `mongod.conf` và mount vào container:

```yaml
# Thêm vào docker-compose.yml
volumes:
  - ./mongod.conf:/etc/mongod.conf
command: mongod --config /etc/mongod.conf --replSet rs0
```

## Monitoring và Maintenance

### Kiểm tra replica set status

```bash
# Trong MongoDB shell
rs.status()
rs.isMaster()
rs.conf()
```

### Xem performance stats

```bash
# Trong MongoDB shell
db.serverStatus()
db.runCommand({replSetGetStatus: 1})
```

### Backup tự động

Tạo cron job cho backup định kỳ:

```bash
# Chỉnh sửa crontab
crontab -e

# Thêm dòng sau để backup hằng ngày lúc 2:00 AM
0 2 * * * /path/to/dqcai-mongorep/setup-dqcai-mongorep.sh backup
```

## Troubleshooting

### Container không khởi động

```bash
# Kiểm tra logs
docker-compose logs mongo1

# Kiểm tra dung lượng disk
df -h

# Kiểm tra memory
free -h
```

### Replica set không khởi tạo được

```bash
# Chạy lại init script
./setup-dqcai-mongorep.sh init

# Hoặc thực hiện thủ công
docker exec mongo1 mongosh --host localhost --port 27017 -u admin -p password123 --authenticationDatabase admin
```

### Primary node bị down

MongoDB sẽ tự động elect primary mới. Để force election:

```bash
# Trong MongoDB shell của secondary node
rs.stepDown()
```

### Performance issues trên Raspberry Pi

1. Giảm memory cache:
```bash
# Trong mongod.conf
storage:
  wiredTiger:
    engineConfig:
      cacheSizeGB: 0.5
```

2. Sử dụng SSD thay vì SD card cho performance tốt hơn

3. Monitor temperature:
```bash
vcgencmd measure_temp
```

## Security Notes

- **LUÔN thay đổi password mặc định** trong file `.env` trước khi deploy
- Sử dụng SSL/TLS cho kết nối trong production
- Cấu hình firewall phù hợp (chỉ mở ports cần thiết)
- Backup encryption cho dữ liệu nhạy cảm
- Không commit file `.env` vào version control
- Sử dụng `.env.local` cho development environment
- Rotate passwords định kỳ
- Monitor logs để phát hiện truy cập bất thường

## Tài liệu tham khảo

- [MongoDB Replica Set Documentation](https://docs.mongodb.com/manual/replication/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Raspberry Pi Docker Best Practices](https://blog.alexellis.io/getting-started-with-docker-on-raspberry-pi/)# MongoDB Replica Set trên Raspberry Pi 5

Hướng dẫn thiết lập MongoDB replica set với 3 node trên Raspberry Pi 5 sử dụng Docker.

## Yêu cầu hệ thống

- Raspberry Pi 5 với ít nhất 4GB RAM
- Docker và Docker Compose đã được cài đặt
- Ít nhất 10GB dung lượng trống

## Cài đặt Docker trên Raspberry Pi 5

```bash
# Cập nhật hệ thống
sudo apt update && sudo apt upgrade -y

# Cài đặt Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Cài đặt Docker Compose
sudo apt install docker-compose-plugin -y

# Khởi động lại để áp dụng quyền
sudo reboot
```

## Cấu trúc thư mục

```
dqcai-mongorep/
├── docker-compose.yml
├── .env
├── setup-dqcai-mongorep.sh
├── init-replica.js
├── scripts/
└── data/
    ├── mongo1/
    ├── mongo2/
    └── mongo3/
```

## Hướng dẫn sử dụng

### 1. Tạo thư mục và copy files

```bash
mkdir dqcai-mongorep
cd dqcai-mongorep

# Copy tất cả các files từ artifacts vào thư mục này
```

### 2. Cấp quyền thực thi cho script

```bash
chmod +x setup-dqcai-mongorep.sh
```

### 3. Khởi tạo replica set (một lệnh duy nhất)

```bash
./setup-dqcai-mongorep.sh setup
```

### 4. Kiểm tra trạng thái

```bash
./setup-dqcai-mongorep.sh status
```

## Các lệnh quản lý

```bash
# Khởi động containers
./setup-dqcai-mongorep.sh start

# Dừng containers
./setup-dqcai-mongorep.sh stop

# Xem logs
./setup-dqcai-mongorep.sh logs

# Xem logs của container cụ thể
./setup-dqcai-mongorep.sh logs mongo1

# Tạo backup
./setup-dqcai-mongorep.sh backup

# Restore từ backup
./setup-dqcai-mongorep.sh restore backup_20241201_120000

# Xóa tất cả dữ liệu (cẩn thận!)
./setup-dqcai-mongorep.sh clean
```

## Kết nối đến MongoDB

### Từ ứng dụng

```javascript
// Connection string cho replica set
const uri = "mongodb://admin:password123@localhost:27017,localhost:27018,localhost:27019/mydb?replicaSet=rs0&authSource=admin";

// Node.js với MongoDB driver
const { MongoClient } = require('mongodb');
const client = new MongoClient(uri);
```

### Từ MongoDB Shell

```bash
# Kết nối đến primary
docker exec -it mongo1 mongosh --host localhost --port 27017 -u admin -p password123 --authenticationDatabase admin

# Hoặc từ host
mongosh "mongodb://admin:password123@localhost:27017,localhost:27018,localhost:27019/admin?replicaSet=rs0"
```

### Mongo Express Web UI

Truy cập: http://localhost:8081
- Username: admin
- Password: webpass123

## Cấu hình nâng cao

### Thay đổi memory limits

Chỉnh sửa file `.env`:

```bash
# Cho Raspberry Pi 5 với 4GB RAM
MONGO_MEMORY_LIMIT=1g
MONGO_EXPRESS_MEMORY_LIMIT=256m

# Cho Raspberry Pi 5 với 8GB RAM
MONGO_MEMORY_LIMIT=2g
MONGO_EXPRESS_MEMORY_LIMIT=512m
```

### Thay đổi ports

Chỉnh sửa file `.env` nếu cần thiết:

```bash
MONGO1_PORT=27017
MONGO2_PORT=27018
MONGO3_PORT=27019
```

### Custom MongoDB configuration

Tạo file `mongod.conf` và mount vào container:

```yaml
# Thêm vào docker-compose.yml
volumes:
  - ./mongod.conf:/etc/mongod.conf
command: mongod --config /etc/mongod.conf --replSet rs0
```

## Monitoring và Maintenance

### Kiểm tra replica set status

```bash
# Trong MongoDB shell
rs.status()
rs.isMaster()
rs.conf()
```

### Xem performance stats

```bash
# Trong MongoDB shell
db.serverStatus()
db.runCommand({replSetGetStatus: 1})
```

### Backup tự động

Tạo cron job cho backup định kỳ:

```bash
# Chỉnh sửa crontab
crontab -e

# Thêm dòng sau để backup hằng ngày lúc 2:00 AM
0 2 * * * /path/to/dqcai-mongorep/setup-dqcai-mongorep.sh backup
```

## Troubleshooting

### Container không khởi động

```bash
# Kiểm tra logs
docker-compose logs mongo1

# Kiểm tra dung lượng disk
df -h

# Kiểm tra memory
free -h
```

### Replica set không khởi tạo được

```bash
# Chạy lại init script
./setup-dqcai-mongorep.sh init

# Hoặc thực hiện thủ công
docker exec mongo1 mongosh --host localhost --port 27017 -u admin -p password123 --authenticationDatabase admin
```

### Primary node bị down

MongoDB sẽ tự động elect primary mới. Để force election:

```bash
# Trong MongoDB shell của secondary node
rs.stepDown()
```

### Performance issues trên Raspberry Pi

1. Giảm memory cache:
```bash
# Trong mongod.conf
storage:
  wiredTiger:
    engineConfig:
      cacheSizeGB: 0.5
```

2. Sử dụng SSD thay vì SD card cho performance tốt hơn

3. Monitor temperature:
```bash
vcgencmd measure_temp
```

## Security Notes

- **LUÔN thay đổi password mặc định** trong file `.env` trước khi deploy
- Sử dụng SSL/TLS cho kết nối trong production
- Cấu hình firewall phù hợp (chỉ mở ports cần thiết)
- Backup encryption cho dữ liệu nhạy cảm
- Không commit file `.env` vào version control
- Sử dụng `.env.local` cho development environment
- Rotate passwords định kỳ
- Monitor logs để phát hiện truy cập bất thường

## Tài liệu tham khảo

- [MongoDB Replica Set Documentation](https://docs.mongodb.com/manual/replication/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Raspberry Pi Docker Best Practices](https://blog.alexellis.io/getting-started-with-docker-on-raspberry-pi/)