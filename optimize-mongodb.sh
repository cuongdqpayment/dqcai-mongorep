#!/bin/bash
echo "🔧 Tối ưu hệ thống cho MongoDB..."

# Tăng vm.max_map_count
echo "📈 Tăng vm.max_map_count..."
sudo sysctl vm.max_map_count=262144
echo 'vm.max_map_count=262144' | sudo tee -a /etc/sysctl.conf

# Tăng giới hạn file descriptors
echo "📁 Tăng file descriptor limits..."
echo '* soft nofile 65536' | sudo tee -a /etc/security/limits.conf
echo '* hard nofile 65536' | sudo tee -a /etc/security/limits.conf

# Tắt swap (nếu có)
echo "💾 Tắt swap..."
sudo swapoff -a
# Comment dòng swap trong /etc/fstab
sudo sed -i '/swap/ s/^/#/' /etc/fstab

# Thiết lập readahead cho storage
echo "🚀 Tối ưu storage readahead..."
sudo blockdev --setra 32 /dev/mmcblk0

echo "✅ Hoàn thành tối ưu! Khởi động lại container:"
echo "docker compose -f docker-compose-single.yml restart mongodb"