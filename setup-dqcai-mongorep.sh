#!/bin/bash
# setup-dqcai-mongorep.sh
# Script để thiết lập và quản lý MongoDB replica set

set -e

# Màu sắc cho output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Load environment variables
load_env() {
    if [ -f .env ]; then
        export $(cat .env | grep -v '^#' | grep -v '^$' | xargs)
        print_status "Environment variables loaded from .env"
    else
        print_error ".env file not found! Please create it first."
        print_status "Creating .env from template..."
        if [ -f .env.example ]; then
            cp .env.example .env
            print_warning "Please edit .env file with your credentials before running setup again"
            exit 1
        else
            print_error "No .env.example found either! Please create .env manually."
            exit 1
        fi
    fi
}

# Tạo thư mục cần thiết
create_directories() {
    print_status "Creating necessary directories..."
    mkdir -p scripts
    mkdir -p data/mongo1
    mkdir -p data/mongo2
    mkdir -p data/mongo3
    mkdir -p /etc/secrets
}

# Chờ container sẵn sàng
wait_for_mongo() {
    print_status "Waiting for MongoDB container to be ready..."
    for i in {1..30}; do
        if docker exec mongo1 mongosh --host mongo1 --port 27017 --eval "db.adminCommand('ping')" >/dev/null 2>&1; then
            print_status "MongoDB is ready!"
            return 0
        fi
        print_status "Waiting for MongoDB... ($i/30)"
        sleep 2
    done
    print_error "MongoDB failed to start in time!"
    exit 1
}

# Tạo người dùng admin
create_admin_user() {
    print_status "Creating admin user..."
    docker exec mongo1 mongosh --host localhost --port 27017 --eval "
        use admin;
        db.createUser({
            user: '$MONGO_ROOT_USERNAME',
            pwd: '$MONGO_ROOT_PASSWORD',
            roles: [{ role: 'root', db: 'admin' }]
        });
    "
}

# Khởi tạo replica set
init_replica_set() {
    print_status "Initializing MongoDB replica set..."
    
    # Tạo file init-replica.js
    cat > scripts/init-replica.js << EOF
if (!rs.status().ok) {
    rs.initiate({
        _id: 'rs0',
        members: [
            { _id: 0, host: 'mongo1:27017' },
            { _id: 1, host: 'mongo2:27017' },
            { _id: 2, host: 'mongo3:27017' }
        ]
    });
}
EOF

    # Copy script vào container
    docker cp scripts/init-replica.js mongo1:/tmp/init-replica.js
    
    # Chạy script khởi tạo với thông tin xác thực
    docker exec mongo1 mongosh --host localhost --port 27017 -u "$MONGO_ROOT_USERNAME" -p "$MONGO_ROOT_PASSWORD" --authenticationDatabase admin /tmp/init-replica.js
    
    print_status "Replica set initialization completed!"
}

# Kiểm tra trạng thái replica set
check_status() {
    print_status "Checking replica set status..."
    docker exec mongo1 mongosh --host localhost --port 27017 -u "$MONGO_ROOT_USERNAME" -p "$MONGO_ROOT_PASSWORD" --authenticationDatabase admin --eval "rs.status()"
}

# Khởi động các container
start_containers() {
    print_status "Starting MongoDB containers..."
    docker compose up -d
    wait_for_mongo
}

# Dừng tất cả containers
stop_containers() {
    print_status "Stopping all MongoDB containers..."
    docker compose down
}

# Xóa tất cả dữ liệu
clean_all() {
    print_warning "This will remove all containers and data!"
    read -p "Are you sure? (y/N): " confirm
    if [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]]; then
        docker compose down -v
        docker volume prune -f
        print_status "All data cleaned!"
    else
        print_status "Operation cancelled."
    fi
}

# Backup dữ liệu
backup_data() {
    print_status "Creating backup..."
    timestamp=$(date +"%Y%m%d_%H%M%S")
    backup_dir="backup_$timestamp"
    mkdir -p $backup_dir
    
    docker exec mongo1 mongodump --host localhost --port 27017 -u "$MONGO_ROOT_USERNAME" -p "$MONGO_ROOT_PASSWORD" --authenticationDatabase admin --out /tmp/backup
    docker cp mongo1:/tmp/backup $backup_dir/
    
    print_status "Backup created in $backup_dir"
}

# Restore dữ liệu
restore_data() {
    if [ -z "$1" ]; then
        print_error "Please specify backup directory: $0 restore <backup_dir>"
        exit 1
    fi
    
    backup_dir=$1
    if [ ! -d "$backup_dir" ]; then
        print_error "Backup directory $backup_dir not found!"
        exit 1
    fi
    
    print_status "Restoring from $backup_dir..."
    docker cp $backup_dir mongo1:/tmp/restore
    docker exec mongo1 mongorestore --host localhost --port 27017 -u "$MONGO_ROOT_USERNAME" -p "$MONGO_ROOT_PASSWORD" --authenticationDatabase admin /tmp/restore/
    
    print_status "Restore completed!"
}

# Hiển thị logs
show_logs() {
    if [ -z "$1" ]; then
        docker compose logs -f
    else
        docker compose logs -f $1
    fi
}

# Menu chính
case "$1" in
    "setup")
        load_env
        create_directories
        start_containers
        create_admin_user
        init_replica_set
        check_status
        print_status "MongoDB replica set is ready!"
        print_status "Primary: localhost:${MONGO1_PORT:-27017}"
        print_status "Secondary 1: localhost:${MONGO2_PORT:-27018}"
        print_status "Secondary 2: localhost:${MONGO3_PORT:-27019}"
        print_status "Mongo Express: http://localhost:${MONGO_EXPRESS_PORT:-8081} (${ME_CONFIG_BASICAUTH_USERNAME}/${ME_CONFIG_BASICAUTH_PASSWORD})"
        ;;
    "start")
        load_env
        start_containers
        ;;
    "stop")
        stop_containers
        ;;
    "status")
        load_env
        check_status
        ;;
    "logs")
        show_logs $2
        ;;
    "backup")
        load_env
        backup_data
        ;;
    "restore")
        load_env
        restore_data $2
        ;;
    "clean")
        clean_all
        ;;
    "init")
        load_env
        init_replica_set
        ;;
    *)
        echo "Usage: $0 {setup|start|stop|status|logs|backup|restore|clean|init}"
        echo ""
        echo "Commands:"
        echo "  setup   - Khởi tạo hoàn chỉnh MongoDB replica set"
        echo "  start   - Khởi động containers"
        echo "  stop    - Dừng containers"
        echo "  status  - Kiểm tra trạng thái replica set"
        echo "  logs    - Xem logs (thêm tên container để xem log cụ thể)"
        echo "  backup  - Tạo backup dữ liệu"
        echo "  restore - Restore dữ liệu từ backup"
        echo "  clean   - Xóa tất cả containers và dữ liệu"
        echo "  init    - Chỉ khởi tạo replica set (nếu containers đã chạy)"
        exit 1
        ;;
esac