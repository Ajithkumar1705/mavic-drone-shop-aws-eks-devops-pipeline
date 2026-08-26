//
// Products
//
db = db.getSiblingDB('catalogue');
db.products.insertMany([
    {sku: 'AICHIP', name: 'Falcon AI Autopilot', description: 'Onboard AI flight controller chip \u2014 handles obstacle avoidance, route planning, and stabilization in real time', price: 2001, instock: 2, categories: ['Artificial Intelligence']},
    {sku: 'AINEURAL', name: 'Nimbus Copilot AI', description: 'Neural-network co-pilot module that learns your flight patterns and anticipates maneuvers', price: 200, instock: 0, categories: ['Artificial Intelligence']},
    {sku: 'QCW', name: 'Aero Quad White', description: 'Classic four-rotor quadcopter with a stabilized camera gimbal \u2014 our most popular all-rounder', price: 953, instock: 15, categories: ['Drone']},
    {sku: 'QCB', name: 'Aero Quad Black', description: 'Blacked-out multi-rotor build with reinforced arms for tougher flying conditions', price: 1024, instock: 8, categories: ['Drone']},
    {sku: 'FOLD', name: 'Skyfold Traveler', description: 'Foldable, portable, and built for range \u2014 slips into a backpack and unfolds when you need it most', price: 1200, instock: 12, categories: ['Drone']},
    {sku: 'AGRI', name: 'AgriWing X8', description: 'Heavy-lift octocopter built for serious agricultural payloads and crop coverage', price: 5000, instock: 10, categories: ['Drone']},
    {sku: 'HELI', name: 'Sentinel Helicopter', description: 'Single-rotor helicopter platform for extended-endurance patrol and survey missions', price: 3200, instock: 4, categories: ['Drone']}
]);

// full text index for searching
db.products.createIndex({
    name: "text",
    description: "text"
});

// unique index for product sku
db.products.createIndex(
    { sku: 1 },
    { unique: true }
);
