// init-mongo.js - Script khởi tạo MongoDB
// Tạo database và user cho ứng dụng

// Chuyển sang database myapp
db = db.getSiblingDB('myapp');

// Tạo user cho ứng dụng
db.createUser({
  user: "appuser",
  pwd: "app-password",
  roles: [
    {
      role: "readWrite",
      db: "myapp"
    }
  ]
});

// Tạo các collection (table) với validation
db.createCollection("users", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["username", "email", "createdAt"],
      properties: {
        username: {
          bsonType: "string",
          description: "Username là bắt buộc và phải là string"
        },
        email: {
          bsonType: "string",
          pattern: "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$",
          description: "Email phải đúng định dạng"
        },
        fullName: {
          bsonType: "string",
          description: "Họ tên đầy đủ"
        },
        createdAt: {
          bsonType: "date",
          description: "Ngày tạo là bắt buộc"
        },
        updatedAt: {
          bsonType: "date",
          description: "Ngày cập nhật"
        }
      }
    }
  }
});

// Tạo collection products
db.createCollection("products", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["name", "price", "category", "createdAt"],
      properties: {
        name: {
          bsonType: "string",
          description: "Tên sản phẩm là bắt buộc"
        },
        price: {
          bsonType: "number",
          minimum: 0,
          description: "Giá phải là số dương"
        },
        category: {
          bsonType: "string",
          description: "Danh mục sản phẩm"
        },
        description: {
          bsonType: "string",
          description: "Mô tả sản phẩm"
        },
        stock: {
          bsonType: "int",
          minimum: 0,
          description: "Số lượng tồn kho"
        },
        createdAt: {
          bsonType: "date",
          description: "Ngày tạo"
        }
      }
    }
  }
});

// Tạo collection orders
db.createCollection("orders", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["userId", "products", "totalAmount", "status", "createdAt"],
      properties: {
        userId: {
          bsonType: "objectId",
          description: "ID người dùng"
        },
        products: {
          bsonType: "array",
          items: {
            bsonType: "object",
            required: ["productId", "quantity", "price"],
            properties: {
              productId: { bsonType: "objectId" },
              quantity: { bsonType: "int", minimum: 1 },
              price: { bsonType: "number", minimum: 0 }
            }
          }
        },
        totalAmount: {
          bsonType: "number",
          minimum: 0
        },
        status: {
          bsonType: "string",
          enum: ["pending", "confirmed", "shipped", "delivered", "cancelled"]
        },
        createdAt: {
          bsonType: "date"
        }
      }
    }
  }
});

// Tạo các index để tối ưu performance
db.users.createIndex({ "username": 1 }, { unique: true });
db.users.createIndex({ "email": 1 }, { unique: true });
db.products.createIndex({ "name": 1 });
db.products.createIndex({ "category": 1 });
db.orders.createIndex({ "userId": 1 });
db.orders.createIndex({ "createdAt": -1 });

// Insert dữ liệu mẫu
db.users.insertMany([
  {
    username: "john_doe",
    email: "john@example.com",
    fullName: "John Doe",
    createdAt: new Date(),
    updatedAt: new Date()
  },
  {
    username: "jane_smith", 
    email: "jane@example.com",
    fullName: "Jane Smith",
    createdAt: new Date(),
    updatedAt: new Date()
  }
]);

db.products.insertMany([
  {
    name: "Laptop Gaming",
    price: 25000000,
    category: "Electronics",
    description: "Laptop gaming cao cấp",
    stock: 10,
    createdAt: new Date()
  },
  {
    name: "Áo thun nam",
    price: 199000,
    category: "Fashion",
    description: "Áo thun cotton 100%",
    stock: 50,
    createdAt: new Date()
  }
]);

print("✅ Database myapp đã được khởi tạo thành công!");
print("📊 Đã tạo các collection: users, products, orders");
print("👤 Đã tạo user: appuser");
print("🔍 Đã tạo các index cần thiết");
print("📝 Đã thêm dữ liệu mẫu");