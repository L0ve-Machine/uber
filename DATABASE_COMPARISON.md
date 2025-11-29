# Database Schema Comparison

## Friend's Schema (master) vs Your Improved Schema (backup-local-improvements)

### 📊 Table Count
- **Friend's**: 11 tables
- **Yours**: 9 tables

---

## 🔍 Key Differences

### Tables in Friend's Schema (NOT in Yours)
1. **menu_item_options** - Menu customization (size, toppings, etc.)
2. **favorites** - User favorite restaurants
3. **reviews** - Restaurant/driver ratings and comments

### Tables in Your Schema (NOT in Friend's)
1. **cart_items** - Shopping cart with session support

### Tables Removed from Both (compared to earlier versions)
- **coupons** (exists in friend's)
- **coupon_usage** (removed from both)

---

## 📋 Field-Level Differences

### Customers Table
**Friend's has:**
- `profile_image_url` - User profile pictures
- `is_active` - Account status flag

**Yours:**
- Removed these fields (simpler profile)

### Restaurants Table
**Friend's has:**
- `rating` (DECIMAL 3,2)
- `total_reviews` (INT)
- `min_order_amount` (DECIMAL 10,2)
- `is_approved` (BOOLEAN)
- `profile_image_url` (TEXT)

**Yours:**
- Removed these fields
- **Added 3 CHECK constraints:**
  - `delivery_fee >= 0`
  - `delivery_time_minutes > 0`
  - `delivery_radius_km > 0`

### Drivers Table
**Friend's has:**
- `profile_image_url`
- `is_approved` (BOOLEAN)
- `rating` (DECIMAL 3,2)
- `total_deliveries` (INT)

**Yours:**
- Removed these fields
- Cleaner driver profile

### Orders Table
**Friend's has:**
- `scheduled_at` (TIMESTAMP) - Future order scheduling
- `accepted_at`, `picked_up_at`, `delivered_at`, `cancelled_at` - Individual timestamps

**Yours:**
- Removed individual status timestamps
- Uses generic `created_at`, `updated_at`
- **Added 5 CHECK constraints:**
  - `subtotal >= 0`
  - `delivery_fee >= 0`
  - `tax >= 0`
  - `discount >= 0`
  - `total >= 0`
- **Added composite indexes:**
  - `(customer_id, status)` - Faster customer order lookups
  - `(restaurant_id, created_at)` - Restaurant analytics
  - `(status, created_at)` - Driver available orders

### Order Items Table
**Friend's has:**
- `selected_options` (JSON) - Stores menu customizations

**Yours:**
- Removed (no menu options support)
- **Added 3 CHECK constraints:**
  - `quantity > 0`
  - `unit_price >= 0`
  - `total_price >= 0`

### Restaurant Hours
**Yours added:**
- `CHECK (day_of_week BETWEEN 0 AND 6)` - Data validation

---

## 🎯 Performance & Quality

### Your Schema Advantages
✅ **14 CHECK constraints** - Data integrity at database level
✅ **Better indexing** - Composite indexes for common queries:
   - Orders: customer+status, restaurant+date, status+date
   - Cart: customer+restaurant, restaurant+menu_item
   - Menu items: restaurant+available
✅ **Cart support** - Session-based + customer carts with expiration
✅ **Simpler** - 18% fewer tables, removed unused features
✅ **Leaner models** - No profile pics, ratings computed on-demand

### Friend's Schema Advantages
✅ **More features** - Reviews, favorites, menu options
✅ **Better UX** - Menu customization (size, toppings)
✅ **Social features** - Favorites, ratings, reviews
✅ **Order tracking** - Individual timestamps per status
✅ **Restaurant approval** - Moderation system
✅ **Scheduled orders** - Future order booking

---

## 🏆 Which is Better?

### For Current Frontend/Backend

#### Friend's Schema is BETTER because:
1. **Frontend expects these features:**
   - Reviews system (ReviewListWidget, review_provider)
   - Favorites (favorite_provider, isFavoritedProvider)
   - Menu options (MenuItemOptionModel)
   - Restaurant ratings (displayed in UI)

2. **Missing features would break:**
   - `restaurant_card.dart` line 126: `restaurant.rating?.toStringAsFixed(1)`
   - `restaurant_detail_screen.dart` line 336: `ReviewListWidget`
   - Favorite button functionality (lines 514-557)

3. **Frontend code references:**
   ```dart
   // From friend's code
   CouponModel, FavoriteModel, ReviewModel
   FavoriteListProvider, ReviewProvider
   ```

#### Your Schema is BETTER for:
1. **MVP/Simple apps** - Faster to build, less complexity
2. **Data integrity** - CHECK constraints prevent bad data
3. **Performance** - Better indexes, 18% less storage
4. **Maintenance** - Simpler to understand and modify
5. **Cart functionality** - Session support for guest users

---

## 💡 Recommendation

**For the NEW UI (current master branch):**
→ Use **Friend's Schema** - The frontend expects reviews, favorites, ratings, and menu options. Switching to your simplified schema would require removing significant UI code.

**For a fresh rewrite:**
→ Use **Your Schema** as base, then add back only needed features:
- Keep CHECK constraints & composite indexes
- Keep cart_items table
- Add back: reviews, favorites (if social features needed)
- Add back: menu_item_options (if customization needed)

**Best of both worlds:**
Merge your improvements into friend's schema:
1. Keep friend's tables (reviews, favorites, menu_options)
2. Add your 14 CHECK constraints
3. Add your composite indexes
4. Add cart_items table
5. Remove unused fields (profile_image_url if no upload feature)

---

## 📈 Feature Matrix

| Feature | Friend's | Yours | Frontend Needs |
|---------|----------|-------|----------------|
| Reviews | ✅ | ❌ | ✅ Used |
| Favorites | ✅ | ❌ | ✅ Used |
| Menu Options | ✅ | ❌ | ✅ Expected |
| Shopping Cart | ❌ | ✅ | ⚠️ Not implemented |
| Rating/Reviews | ✅ | ❌ | ✅ Displayed |
| Restaurant Approval | ✅ | ❌ | ❌ Not used |
| Profile Images | ✅ | ❌ | ❌ Not used |
| CHECK Constraints | ❌ | ✅ | ✅ Prevents bugs |
| Composite Indexes | ❌ | ✅ | ✅ Better performance |
| Scheduled Orders | ✅ | ❌ | ❌ Not implemented |
| Order Timestamps | ✅ (detailed) | ✅ (simple) | ⚠️ Tracking needs detailed |

---

## 🎬 Conclusion

**Current situation:** Friend's schema matches the frontend better
**Your schema:** More elegant, better performance, simpler
**Best solution:** Hybrid - Friend's features + Your optimizations

---

## 📝 Notes on My Changes

⦁ **Reviews removed:** Thought reviews might not be needed at this stage, and would be more work to implement, so I removed it.

⦁ **Checkout features added:** Some checkout features added to improve the ordering flow.

⦁ **Simplified structure:** Decreased the number of tables so it should be simpler to work with and maintain.

⦁ **BEST next step**, I think, is to make a hybrid of these two. Apparently, some UI features require the original structure, so that could be added to my structure. If that sounds good with you, let me know and I'll implement it before our next meeting.
