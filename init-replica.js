// init-replica.js
// Script để khởi tạo MongoDB Replica Set

// Cấu hình replica set
const config = {
  "_id": "rs0",
  "version": 1,
  "members": [
    {
      "_id": 0,
      "host": "mongo1:27017",
      "priority": 2
    },
    {
      "_id": 1,
      "host": "mongo2:27017",
      "priority": 1
    },
    {
      "_id": 2,
      "host": "mongo3:27017",
      "priority": 1
    }
  ]
};

// Khởi tạo replica set
try {
  const result = rs.initiate(config);
  print("Replica set initiation result:");
  printjson(result);
  
  if (result.ok === 1) {
    print("✅ Replica set initialized successfully!");
    print("Waiting for replica set to stabilize...");
    
    // Chờ replica set ổn định
    let attempts = 0;
    const maxAttempts = 30;
    
    while (attempts < maxAttempts) {
      try {
        const status = rs.status();
        if (status.ok === 1) {
          print("✅ Replica set is ready!");
          printjson(status);
          break;
        }
      } catch (e) {
        print(`Attempt ${attempts + 1}/${maxAttempts}: Waiting for replica set...`);
        sleep(5000); // Chờ 5 giây
      }
      attempts++;
    }
    
    if (attempts >= maxAttempts) {
      print("⚠️  Replica set took longer than expected to initialize");
    }
    
  } else {
    print("❌ Failed to initialize replica set:");
    printjson(result);
  }
} catch (error) {
  print("❌ Error initializing replica set:");
  print(error);
}