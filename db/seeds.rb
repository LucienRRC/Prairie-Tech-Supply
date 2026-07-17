[
  ["Computer Components", "Computer parts, storage, memory, and upgrades."],
  ["Gaming", "Gaming keyboards, mice, monitors, and accessories."],
  ["Audio", "Headphones, speakers, microphones, and audio accessories."],
  ["Networking", "Routers, switches, adapters, and network accessories."],
  ["Mobile Accessories", "Chargers, cables, power banks, and phone accessories."],
  ["Smart Home", "Cameras, sensors, and connected home devices."]
].each do |name, description|
  category = Category.find_or_initialize_by(name: name)
  category.update!(description: description)
end

products = [
  ["CMP-SSD-001", "Samsung 990 PRO 2TB NVMe SSD", "Samsung", "Computer Components", 249.99, 18, "High-performance PCIe 4.0 NVMe solid-state drive with fast read and write speeds for gaming PCs and professional workstations."],
  ["CMP-RAM-002", "Corsair Vengeance 32GB DDR5 Memory Kit", "Corsair", "Computer Components", 139.99, 24, "A 32GB dual-channel DDR5 memory kit designed for dependable multitasking, content creation, and modern PC gaming."],
  ["GAM-KEY-003", "Keychron K8 Pro Wireless Mechanical Keyboard", "Keychron", "Gaming", 149.99, 15, "A tenkeyless mechanical keyboard with wireless connectivity, hot-swappable switches, and customizable RGB backlighting."],
  ["GAM-MSE-004", "Logitech G502 X Gaming Mouse", "Logitech", "Gaming", 109.99, 21, "A lightweight wired gaming mouse with a precise HERO sensor, adjustable controls, and redesigned hybrid optical-mechanical switches."],
  ["AUD-HDP-005", "Sony WH-1000XM5 Wireless Headphones", "Sony", "Audio", 499.99, 9, "Premium wireless headphones featuring adaptive noise cancellation, clear hands-free calling, and long battery life."],
  ["AUD-MIC-006", "Blue Yeti USB Microphone", "Logitech G", "Audio", 169.99, 13, "A versatile USB condenser microphone with multiple pickup patterns for streaming, podcasts, meetings, and voice recording."],
  ["NET-RTR-007", "TP-Link Archer AX55 Wi-Fi 6 Router", "TP-Link", "Networking", 129.99, 17, "A dual-band Wi-Fi 6 router offering reliable coverage, improved capacity, and gigabit wired connections for busy homes."],
  ["MOB-PWR-008", "Anker 737 24,000mAh Power Bank", "Anker", "Mobile Accessories", 199.99, 12, "A high-capacity portable charger with fast USB-C charging and a digital display for laptops, tablets, and mobile phones."],
  ["SMT-CAM-009", "Google Nest Cam Indoor Wired", "Google", "Smart Home", 129.99, 14, "A wired indoor security camera with intelligent alerts, clear video, night vision, and convenient Google Home integration."],
  ["SMT-PLG-010", "Kasa Smart Wi-Fi Plug Mini 4-Pack", "Kasa", "Smart Home", 44.99, 30, "Compact smart plugs that add app control, schedules, timers, and voice control to lamps and small household appliances."],
  ["MOB-CHG-011", "Belkin BoostCharge Pro 3-in-1 Wireless Charger", "Belkin", "Mobile Accessories", 189.99, 11, "A compact charging stand designed to charge compatible phones, wireless earbuds, and smartwatches from one location."],
  ["NET-SWT-012", "NETGEAR GS308 8-Port Gigabit Ethernet Switch", "NETGEAR", "Networking", 39.99, 26, "A quiet unmanaged eight-port gigabit switch for expanding reliable wired network connections at home or in a small office."]
]

products.each do |sku, name, brand, category_name, price, stock, description|
  product = Product.find_or_initialize_by(sku: sku)
  product.update!(
    name: name,
    brand: brand,
    category: Category.find_by!(name: category_name),
    price: price,
    stock_quantity: stock,
    description: description,
    active: true
  )
end

product_image_path = Rails.root.join("app/assets/images/computer-technology.jpg")
raise "Missing default product image: #{product_image_path}" unless product_image_path.exist?

products_with_images = Product.with_attached_image.to_a
old_blobs = products_with_images.filter_map { |product| product.image.blob if product.image.attached? }.uniq
products_with_images.each { |product| product.image.detach if product.image.attached? }
old_blobs.each(&:purge)

shared_product_image = ActiveStorage::Blob.create_and_upload!(
  io: File.open(product_image_path, "rb"),
  filename: product_image_path.basename.to_s,
  content_type: Marcel::MimeType.for(product_image_path)
)
Product.find_each { |product| product.image.attach(shared_product_image) }

SitePage.find_or_initialize_by(slug: "about").update!(
  title: "About Prairie Tech Supply",
  body: "Prairie Tech Supply is a locally owned electronics retailer serving Winnipeg for eight years. Our twelve-person team includes sales associates, warehouse staff, repair technicians, and customer service specialists.\n\nWe help students, gamers, remote workers, families, and small businesses find dependable technology without losing the personal support of a neighbourhood store."
)

SitePage.find_or_initialize_by(slug: "contact").update!(
  title: "Contact Us",
  body: "Questions about a product, local delivery, or a repair pickup? Our Winnipeg team is ready to help.\n\nEmail: support@prairietech.example\nPhone: 204-555-0148\nHours: Monday to Saturday, 9:00 AM to 6:00 PM"
)

admin = AdminUser.find_or_initialize_by(username: "admin")
admin.email = "admin@example.com"
admin.password = "password"
admin.password_confirmation = "password"
admin.save!
