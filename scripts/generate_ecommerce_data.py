"""
Ecommerce Synthetic Data Generator
Generates exactly 550,759 records across 8 relational tables for commercial performance analytics:
1. raw_customers: 96,096 records
2. raw_orders: 99,441 records
3. raw_order_items: 112,650 records
4. raw_order_payments: 103,886 records
5. raw_order_reviews: 99,224 records
6. raw_products: 32,951 records
7. raw_sellers: 3,095 records
8. raw_promotions: 3,416 records
Total: 550,759 records

Ensures exact cent-level reconciliation between order items (price + freight)
and order payments (payment_value) to support grain-aware transformation tests.
"""

import os
import sys
import random
import datetime
from decimal import Decimal, ROUND_HALF_UP
import duckdb

# Set fixed seed for 100% reproducible data generation
RANDOM_SEED = 42
random.seed(RANDOM_SEED)

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA_DIR = os.path.join(BASE_DIR, "data")
RAW_DIR = os.path.join(DATA_DIR, "raw")
DB_PATH = os.path.join(DATA_DIR, "ecommerce.duckdb")

os.makedirs(RAW_DIR, exist_ok=True)

# Target counts
COUNT_CUSTOMERS = 96096
COUNT_ORDERS = 99441
COUNT_ITEMS = 112650
COUNT_PAYMENTS = 103886
COUNT_REVIEWS = 99224
COUNT_PRODUCTS = 32951
COUNT_SELLERS = 3095
COUNT_PROMOTIONS = 3416

TOTAL_EXPECTED = (
    COUNT_CUSTOMERS
    + COUNT_ORDERS
    + COUNT_ITEMS
    + COUNT_PAYMENTS
    + COUNT_REVIEWS
    + COUNT_PRODUCTS
    + COUNT_SELLERS
    + COUNT_PROMOTIONS
)

assert TOTAL_EXPECTED == 550759, f"Total expected must be 550759, got {TOTAL_EXPECTED}"

CITIES_STATES = [
    ("sao paulo", "SP"), ("rio de janeiro", "RJ"), ("belo horizonte", "MG"),
    ("curitiba", "PR"), ("porto alegre", "RS"), ("salvador", "BA"),
    ("brasilia", "DF"), ("fortaleza", "CE"), ("recife", "PE"),
    ("campinas", "SP"), ("florianopolis", "SC"), ("goiania", "GO"),
    ("belem", "PA"), ("manaus", "AM"), ("vitoria", "ES"),
    ("santos", "SP"), ("sao bernardo do campo", "SP"), ("guarulhos", "SP"),
    ("niteroi", "RJ"), ("ribeirao preto", "SP")
]

CATEGORIES = [
    "health_beauty", "computers_accessories", "bed_bath_table", "sports_leisure",
    "furniture_decor", "telephony", "watches_gifts", "auto",
    "housewares", "garden_tools", "electronics", "baby",
    "stationery", "cool_stuff", "pet_shop", "toys",
    "perfumery", "fashion_bags_accessories", "consoles_games", "office_furniture"
]

ORDER_STATUSES = ["delivered", "delivered", "delivered", "delivered", "delivered", "delivered", "delivered", "delivered", "shipped", "canceled"]
PAYMENT_TYPES = ["credit_card", "credit_card", "credit_card", "boleto", "voucher", "debit_card"]

def round_cents(val):
    return Decimal(str(val)).quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)

def generate_data():
    print(f"[1/8] Generating {COUNT_SELLERS:,} sellers...")
    sellers = []
    seller_ids = [f"s_{i+1:06d}" for i in range(COUNT_SELLERS)]
    for s_id in seller_ids:
        city, state = random.choice(CITIES_STATES)
        zip_code = f"{random.randint(10000, 99999)}"
        sellers.append((s_id, zip_code, city, state))

    print(f"[2/8] Generating {COUNT_PRODUCTS:,} products...")
    products = []
    product_ids = [f"p_{i+1:06d}" for i in range(COUNT_PRODUCTS)]
    for p_id in product_ids:
        cat = random.choice(CATEGORIES)
        name_len = random.randint(20, 60)
        desc_len = random.randint(150, 2500)
        photos = random.randint(1, 8)
        weight_g = random.randint(100, 15000)
        len_cm = random.randint(10, 80)
        h_cm = random.randint(2, 60)
        w_cm = random.randint(10, 70)
        products.append((p_id, cat, name_len, desc_len, photos, weight_g, len_cm, h_cm, w_cm))

    print(f"[3/8] Generating {COUNT_PROMOTIONS:,} promotions...")
    promos = []
    promo_ids = [f"promo_{i+1:06d}" for i in range(COUNT_PROMOTIONS)]
    promo_channels = ["Email", "Affiliate", "Paid Search", "Social", "Direct", "Influencer"]
    promo_codes = ["WELCOME10", "SUMMER2023", "BLACKFRIDAY", "SPRING24", "CYBER2023", "FLASH20", "VIPMEMBER", "HOLIDAY30"]
    base_date = datetime.date(2023, 1, 1)
    for p_id in promo_ids:
        code = f"{random.choice(promo_codes)}_{random.randint(10, 99)}"
        disc = random.choice([0.05, 0.10, 0.15, 0.20, 0.25])
        channel = random.choice(promo_channels)
        start_offset = random.randint(0, 650)
        val_from = base_date + datetime.timedelta(days=start_offset)
        val_to = val_from + datetime.timedelta(days=random.randint(7, 60))
        is_active = 1 if val_to >= datetime.date(2024, 6, 1) else 0
        promos.append((p_id, code, disc, channel, val_from.isoformat(), val_to.isoformat(), is_active))

    print(f"[4/8] Generating {COUNT_CUSTOMERS:,} customers...")
    customers = []
    customer_ids = [f"c_{i+1:06d}" for i in range(COUNT_CUSTOMERS)]
    # ~85,000 unique buyers, creating repeat customers
    num_unique = 85000
    unique_ids = [f"u_{i+1:06d}" for i in range(num_unique)]
    for i, c_id in enumerate(customer_ids):
        u_id = unique_ids[i] if i < num_unique else random.choice(unique_ids)
        city, state = random.choice(CITIES_STATES)
        zip_code = f"{random.randint(10000, 99999)}"
        created_date = (datetime.date(2023, 1, 1) + datetime.timedelta(days=random.randint(0, 700))).isoformat()
        customers.append((c_id, u_id, zip_code, city, state, created_date))

    print(f"[5/8] Generating {COUNT_ORDERS:,} orders...")
    orders = []
    order_ids = [f"o_{i+1:06d}" for i in range(COUNT_ORDERS)]
    start_dt = datetime.datetime(2023, 1, 1, 8, 0, 0)
    
    # Store order timestamps and statuses for items & payments
    order_meta = {}
    for i, o_id in enumerate(order_ids):
        c_id = customer_ids[i % COUNT_CUSTOMERS]
        status = random.choice(ORDER_STATUSES)
        days_offset = random.randint(0, 715)
        secs_offset = random.randint(0, 86400)
        purch_dt = start_dt + datetime.timedelta(days=days_offset, seconds=secs_offset)
        
        appr_dt = purch_dt + datetime.timedelta(minutes=random.randint(15, 240))
        carrier_dt = appr_dt + datetime.timedelta(days=random.randint(1, 3))
        deliv_dt = carrier_dt + datetime.timedelta(days=random.randint(2, 12))
        est_dt = purch_dt + datetime.timedelta(days=random.randint(12, 28))
        
        purch_str = purch_dt.strftime("%Y-%m-%d %H:%M:%S")
        appr_str = appr_dt.strftime("%Y-%m-%d %H:%M:%S")
        
        if status == "delivered":
            carrier_str = carrier_dt.strftime("%Y-%m-%d %H:%M:%S")
            deliv_str = deliv_dt.strftime("%Y-%m-%d %H:%M:%S")
        elif status == "shipped":
            carrier_str = carrier_dt.strftime("%Y-%m-%d %H:%M:%S")
            deliv_str = None
        else: # canceled
            carrier_str = None
            deliv_str = None
            
        est_str = est_dt.strftime("%Y-%m-%d")
        
        orders.append((o_id, c_id, status, purch_str, appr_str, carrier_str, deliv_str, est_str))
        order_meta[o_id] = {
            "status": status,
            "purch_dt": purch_dt,
            "deliv_str": deliv_str
        }

    print(f"[6/8] Generating {COUNT_ITEMS:,} order items...")
    # Allocate 112,650 items across 99,441 orders.
    # Every order gets at least 1 item = 99,441 items.
    # Remaining 13,209 items distributed to multi-item orders.
    extra_items_needed = COUNT_ITEMS - COUNT_ORDERS # 13,209
    items_per_order = {o_id: 1 for o_id in order_ids}
    
    # Pick orders to receive 2nd or 3rd items
    multi_order_sample = random.sample(order_ids, extra_items_needed)
    for o_id in multi_order_sample:
        items_per_order[o_id] += 1

    order_items = []
    order_total_item_amounts = {} # o_id -> Decimal total
    
    for o_id in order_ids:
        num_items = items_per_order[o_id]
        o_purch_dt = order_meta[o_id]["purch_dt"]
        ship_limit = (o_purch_dt + datetime.timedelta(days=7)).strftime("%Y-%m-%d %H:%M:%S")
        
        o_sum = Decimal("0.00")
        for seq in range(1, num_items + 1):
            p_id = random.choice(product_ids)
            s_id = random.choice(seller_ids)
            # Price distribution
            base_cents = random.choices(
                [random.randint(990, 4990), random.randint(5000, 19900), random.randint(20000, 79900)],
                weights=[0.55, 0.35, 0.10]
            )[0]
            price = round_cents(Decimal(base_cents) / Decimal("100"))
            freight = round_cents(Decimal(random.randint(450, 3500)) / Decimal("100"))
            
            order_items.append((o_id, seq, p_id, s_id, ship_limit, float(price), float(freight)))
            o_sum += (price + freight)
        order_total_item_amounts[o_id] = o_sum

    assert len(order_items) == COUNT_ITEMS, f"Items count mismatch: {len(order_items)} vs {COUNT_ITEMS}"

    print(f"[7/8] Generating {COUNT_PAYMENTS:,} payments with EXACT CENT RECONCILIATION...")
    # Allocate 103,886 payments across 99,441 orders.
    # Every order gets at least 1 payment = 99,441 payments.
    # Remaining 4,445 payments distributed as split payments (e.g., voucher + credit card).
    extra_payments_needed = COUNT_PAYMENTS - COUNT_ORDERS # 4,445
    payments_per_order = {o_id: 1 for o_id in order_ids}
    split_order_sample = set(random.sample(order_ids, extra_payments_needed))
    for o_id in split_order_sample:
        payments_per_order[o_id] = 2

    order_payments = []
    total_payments_reconciled = Decimal("0.00")
    total_items_reconciled = Decimal("0.00")

    for o_id in order_ids:
        num_pmts = payments_per_order[o_id]
        total_order_val = order_total_item_amounts[o_id]
        total_items_reconciled += total_order_val

        if num_pmts == 1:
            ptype = random.choice(PAYMENT_TYPES)
            inst = random.randint(1, 10) if ptype == "credit_card" else 1
            order_payments.append((o_id, 1, ptype, inst, float(total_order_val)))
            total_payments_reconciled += total_order_val
        else:
            # 2 payments: voucher/gift + credit_card
            # Voucher takes part of total, remaining goes to credit_card
            # Exact cents partition!
            half_cents = int((total_order_val * 100) // 3)
            if half_cents < 500:
                half_cents = min(int(total_order_val * 100), 500)
            pmt1_val = round_cents(Decimal(half_cents) / Decimal("100"))
            pmt2_val = total_order_val - pmt1_val
            
            order_payments.append((o_id, 1, "voucher", 1, float(pmt1_val)))
            order_payments.append((o_id, 2, "credit_card", random.randint(1, 6), float(pmt2_val)))
            total_payments_reconciled += (pmt1_val + pmt2_val)

    assert len(order_payments) == COUNT_PAYMENTS, f"Payments count mismatch: {len(order_payments)} vs {COUNT_PAYMENTS}"
    diff = abs(total_payments_reconciled - total_items_reconciled)
    assert diff == Decimal("0.00"), f"Source revenue reconciliation error: delta is {diff} cents!"
    print(f"   [OK] Revenue parity verified: Items sum ${total_items_reconciled:,.2f} == Payments sum ${total_payments_reconciled:,.2f} (Delta: $0.00)")

    print(f"[8/8] Generating {COUNT_REVIEWS:,} reviews...")
    # 99,224 reviews for 99,441 orders (almost all delivered orders reviewed)
    review_order_sample = random.sample(order_ids, COUNT_REVIEWS)
    order_reviews = []
    review_titles = [
        "Recomendo", "Excelente", "Muito bom", "Produto de qualidade",
        "Chegou rapido", "Perfeito", "Gostei", "Otimo atendimento",
        "Nao recomendo", "Demorou a entrega", "Veio com defeito", None
    ]
    
    for i, o_id in enumerate(review_order_sample):
        r_id = f"rev_{i+1:06d}"
        score = random.choices([5, 4, 3, 2, 1], weights=[0.58, 0.19, 0.08, 0.04, 0.11])[0]
        title = random.choice(review_titles)
        deliv_date_str = order_meta[o_id]["deliv_str"]
        if deliv_date_str:
            base_rev_dt = datetime.datetime.strptime(deliv_date_str, "%Y-%m-%d %H:%M:%S")
        else:
            base_rev_dt = order_meta[o_id]["purch_dt"] + datetime.timedelta(days=15)
            
        c_dt = base_rev_dt + datetime.timedelta(days=random.randint(1, 3))
        a_dt = c_dt + datetime.timedelta(hours=random.randint(6, 48))
        order_reviews.append((r_id, o_id, score, title, c_dt.strftime("%Y-%m-%d"), a_dt.strftime("%Y-%m-%d %H:%M:%S")))

    assert len(order_reviews) == COUNT_REVIEWS

    total_records = (
        len(customers) + len(orders) + len(order_items) +
        len(order_payments) + len(order_reviews) + len(products) +
        len(sellers) + len(promos)
    )
    print(f"\n=======================================================")
    print(f" TOTAL RECORDS GENERATED: {total_records:,} (Target: {TOTAL_EXPECTED:,})")
    print(f"=======================================================")

    print("Writing to DuckDB database and CSV raw source files...")
    con = duckdb.connect(DB_PATH)

    # 1. raw_customers
    con.execute("""
        CREATE OR REPLACE TABLE raw_customers (
            customer_id VARCHAR PRIMARY KEY,
            customer_unique_id VARCHAR,
            customer_zip_code VARCHAR,
            customer_city VARCHAR,
            customer_state VARCHAR,
            created_at VARCHAR
        )
    """)
    con.executemany("INSERT INTO raw_customers VALUES (?, ?, ?, ?, ?, ?)", customers)
    con.execute(f"COPY raw_customers TO '{os.path.join(RAW_DIR, 'raw_customers.csv').replace(chr(92), '/')}' (HEADER, DELIMITER ',')")

    # 2. raw_orders
    con.execute("""
        CREATE OR REPLACE TABLE raw_orders (
            order_id VARCHAR PRIMARY KEY,
            customer_id VARCHAR,
            order_status VARCHAR,
            order_purchase_timestamp VARCHAR,
            order_approved_at VARCHAR,
            order_delivered_carrier_date VARCHAR,
            order_delivered_customer_date VARCHAR,
            order_estimated_delivery_date VARCHAR
        )
    """)
    con.executemany("INSERT INTO raw_orders VALUES (?, ?, ?, ?, ?, ?, ?, ?)", orders)
    con.execute(f"COPY raw_orders TO '{os.path.join(RAW_DIR, 'raw_orders.csv').replace(chr(92), '/')}' (HEADER, DELIMITER ',')")

    # 3. raw_order_items
    con.execute("""
        CREATE OR REPLACE TABLE raw_order_items (
            order_id VARCHAR,
            order_item_id INTEGER,
            product_id VARCHAR,
            seller_id VARCHAR,
            shipping_limit_date VARCHAR,
            price DECIMAL(10, 2),
            freight_value DECIMAL(10, 2)
        )
    """)
    con.executemany("INSERT INTO raw_order_items VALUES (?, ?, ?, ?, ?, ?, ?)", order_items)
    con.execute(f"COPY raw_order_items TO '{os.path.join(RAW_DIR, 'raw_order_items.csv').replace(chr(92), '/')}' (HEADER, DELIMITER ',')")

    # 4. raw_order_payments
    con.execute("""
        CREATE OR REPLACE TABLE raw_order_payments (
            order_id VARCHAR,
            payment_sequential INTEGER,
            payment_type VARCHAR,
            payment_installments INTEGER,
            payment_value DECIMAL(10, 2)
        )
    """)
    con.executemany("INSERT INTO raw_order_payments VALUES (?, ?, ?, ?, ?)", order_payments)
    con.execute(f"COPY raw_order_payments TO '{os.path.join(RAW_DIR, 'raw_order_payments.csv').replace(chr(92), '/')}' (HEADER, DELIMITER ',')")

    # 5. raw_order_reviews
    con.execute("""
        CREATE OR REPLACE TABLE raw_order_reviews (
            review_id VARCHAR PRIMARY KEY,
            order_id VARCHAR,
            review_score INTEGER,
            review_comment_title VARCHAR,
            review_creation_date VARCHAR,
            review_answer_timestamp VARCHAR
        )
    """)
    con.executemany("INSERT INTO raw_order_reviews VALUES (?, ?, ?, ?, ?, ?)", order_reviews)
    con.execute(f"COPY raw_order_reviews TO '{os.path.join(RAW_DIR, 'raw_order_reviews.csv').replace(chr(92), '/')}' (HEADER, DELIMITER ',')")

    # 6. raw_products
    con.execute("""
        CREATE OR REPLACE TABLE raw_products (
            product_id VARCHAR PRIMARY KEY,
            product_category_name VARCHAR,
            product_name_length INTEGER,
            product_description_length INTEGER,
            product_photos_qty INTEGER,
            product_weight_g INTEGER,
            product_length_cm INTEGER,
            product_height_cm INTEGER,
            product_width_cm INTEGER
        )
    """)
    con.executemany("INSERT INTO raw_products VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)", products)
    con.execute(f"COPY raw_products TO '{os.path.join(RAW_DIR, 'raw_products.csv').replace(chr(92), '/')}' (HEADER, DELIMITER ',')")

    # 7. raw_sellers
    con.execute("""
        CREATE OR REPLACE TABLE raw_sellers (
            seller_id VARCHAR PRIMARY KEY,
            seller_zip_code_prefix VARCHAR,
            seller_city VARCHAR,
            seller_state VARCHAR
        )
    """)
    con.executemany("INSERT INTO raw_sellers VALUES (?, ?, ?, ?)", sellers)
    con.execute(f"COPY raw_sellers TO '{os.path.join(RAW_DIR, 'raw_sellers.csv').replace(chr(92), '/')}' (HEADER, DELIMITER ',')")

    # 8. raw_promotions
    con.execute("""
        CREATE OR REPLACE TABLE raw_promotions (
            promo_id VARCHAR PRIMARY KEY,
            promo_code VARCHAR,
            discount_pct DECIMAL(5, 2),
            channel VARCHAR,
            valid_from VARCHAR,
            valid_to VARCHAR,
            is_active INTEGER
        )
    """)
    con.executemany("INSERT INTO raw_promotions VALUES (?, ?, ?, ?, ?, ?, ?)", promos)
    con.execute(f"COPY raw_promotions TO '{os.path.join(RAW_DIR, 'raw_promotions.csv').replace(chr(92), '/')}' (HEADER, DELIMITER ',')")

    con.close()
    print("[SUCCESS] Successfully created tables in DuckDB and exported raw CSV files!")

if __name__ == "__main__":
    generate_data()
