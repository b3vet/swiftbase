# Phase 9: AdminUI Integration Testing Guide

This guide will help you systematically test the AdminUI integration with the SwiftBase backend.

## Prerequisites

Before starting, ensure you have:
- ✅ Built the backend successfully (`swift build`)
- ✅ Built the AdminUI (`cd AdminUI && pnpm build`)
- ✅ Static files exist in `Sources/SwiftBase/Resources/Public/`

---

## Step 1: Create Admin User

First, we need to create an admin user in the database since the AdminUI requires admin authentication.

### 1.1 Run database migrations and seeding

The project includes a default seeder that creates an admin user automatically.

**Action:**
```bash
# Run migrations (if not already done)
swift run SwiftBase migrate

# Seed the database with default admin user
swift run SwiftBase seed
```

**Expected outcome:**
```
[INFO] Seeding database...
[INFO] Running all seeders...
Default admin created:
  Username: admin
  Password: admin123
  IMPORTANT: Change this password immediately!
[INFO] Database seeding completed!
```

**Default Admin Credentials:**
- Username: `admin`
- Password: `admin123`

**Status:** ⬜ Not started | ⬜ In progress | ⬜ Completed | ⬜ Issues found

**Issues encountered:**
```
(Report any errors or unexpected behavior here)
```

---

## Step 2: Start the Backend Server

### 2.1 Run the backend server

**Action:**
```bash
swift run SwiftBase
```

**Expected outcome:**
```
[INFO] Database initialized at: ./data/swiftbase.db
[INFO] SwiftBase application configured on 127.0.0.1:8090
[INFO] Starting SwiftBase server on 127.0.0.1:8090
```

**Status:** ⬜ Not started | ⬜ In progress | ⬜ Completed | ⬜ Issues found

**Issues encountered:**
```
(Report any errors or unexpected behavior here)
```

---

## Step 3: Access the AdminUI

### 3.1 Open AdminUI in browser

**Action:**
- Open your browser and navigate to: `http://localhost:8090/admin/`

**Expected outcome:**
- AdminUI login page should load
- No console errors in browser developer tools (F12)
- Page should display the SwiftBase admin login form

**Status:** ⬜ Not started | ⬜ In progress | ⬜ Completed | ⬜ Issues found

**Issues encountered:**
```
(Report any errors or unexpected behavior here)
```

### 3.2 Check browser console

**Action:**
- Press F12 to open developer tools
- Check the Console tab for any errors
- Check the Network tab to verify asset loading

**Expected outcome:**
- All assets should load successfully (200 status codes)
- Files loaded:
  - `index.html`
  - `assets/index-*.js`
  - `assets/index-*.css`
  - `assets/vendor-*.js`
- No CORS errors
- No 404 errors

**Status:** ⬜ Not started | ⬜ In progress | ⬜ Completed | ⬜ Issues found

**Issues encountered:**
```
(Report any errors or unexpected behavior here)
```

---

## Step 4: Test Admin Login

### 4.1 Attempt admin login

**Action:**
- Enter admin credentials:
  - Username: `admin`
  - Password: `admin123`
- Click "Login" button

**Expected outcome:**
- Login request sent to `POST /api/admin/login`
- Response includes access token and refresh token
- Redirect to dashboard at `http://localhost:8090/admin/#/`
- Dashboard shows stats cards

**Status:** ⬜ Not started | ⬜ In progress | ⬜ Completed | ⬜ Issues found

**Issues encountered:**
```
(Report any errors or unexpected behavior here)
```

### 4.2 Verify authentication persistence

**Action:**
- Refresh the page (F5)

**Expected outcome:**
- Should remain logged in
- Should still be on dashboard
- No redirect to login page

**Status:** ⬜ Not started | ⬜ In progress | ⬜ Completed | ⬜ Issues found

**Issues encountered:**
```
(Report any errors or unexpected behavior here)
```

---

## Step 5: Test Dashboard

### 5.1 Verify dashboard loads

**Action:**
- Check if dashboard displays correctly
- Look for stat cards showing:
  - Collections count
  - Users count
  - Documents count
  - Storage usage

**Expected outcome:**
- Dashboard renders without errors
- Stats display (may be 0 initially)
- Navigation sidebar visible on left
- All menu items present

**Status:** ⬜ Not started | ⬜ In progress | ⬜ Completed | ⬜ Issues found

**Issues encountered:**
```
(Report any errors or unexpected behavior here)
```

---

## Step 6: Test Collection Management

### 6.1 Navigate to Collections page

**Action:**
- Click "Collections" in the sidebar

**Expected outcome:**
- URL changes to `http://localhost:8090/admin/#/collections`
- Collections list page loads
- Shows empty state or existing collections

**Status:** ⬜ Not started | ⬜ In progress | ⬜ Completed | ⬜ Issues found

**Issues encountered:**
```
(Report any errors or unexpected behavior here)
```

### 6.2 Create a new collection

**Action:**
- Click "New Collection" button
- Enter collection name: `test_users`
- (Optional) Add schema, indexes
- Click "Create Collection"

**Expected outcome:**
- Request sent to `POST /api/admin/collections`
- Success message displayed
- New collection appears in the list
- Collection has stats (0 documents initially)

**Status:** ⬜ Not started | ⬜ In progress | ⬜ Completed | ⬜ Issues found

**Issues encountered:**
```
(Report any errors or unexpected behavior here)
```

### 6.3 View collection details

**Action:**
- Click on the newly created collection

**Expected outcome:**
- URL changes to `http://localhost:8090/admin/#/collections/test_users`
- Collection details page loads
- Shows collection metadata, schema, indexes

**Status:** ⬜ Not started | ⬜ In progress | ⬜ Completed | ⬜ Issues found

**Issues encountered:**
```
(Report any errors or unexpected behavior here)
```

---

## Step 7: Test Document Management

### 7.1 Navigate to Documents page

**Action:**
- From the collection detail page, click "View Documents" OR
- Navigate to Documents from the sidebar

**Expected outcome:**
- Document list page loads
- Shows empty state (no documents yet)
- "New Document" button visible

**Status:** ⬜ Not started | ⬜ In progress | ⬜ Completed | ⬜ Issues found

**Issues encountered:**
```
(Report any errors or unexpected behavior here)
```

### 7.2 Create a new document

**Action:**
- Click "New Document" button
- Enter JSON data:
```json
{
  "name": "John Doe",
  "email": "john@example.com",
  "age": 30
}
```
- Click "Create"

**Expected outcome:**
- Request sent to `POST /api/query` with action "create"
- Success message displayed
- Document appears in the list with an auto-generated ID

**Status:** ⬜ Not started | ⬜ In progress | ⬜ Completed | ⬜ Issues found

**Issues encountered:**
```
(Report any errors or unexpected behavior here)
```

### 7.3 Edit the document

**Action:**
- Click "Edit" on the created document
- Modify the JSON (e.g., change age to 31)
- Click "Save"

**Expected outcome:**
- Request sent to `POST /api/query` with action "update"
- Success message displayed
- Document updated in the list

**Status:** ⬜ Not started | ⬜ In progress | ⬜ Completed | ⬜ Issues found

**Issues encountered:**
```
(Report any errors or unexpected behavior here)
```

### 7.4 Delete the document

**Action:**
- Click "Delete" on the document
- Confirm deletion

**Expected outcome:**
- Confirmation modal appears
- After confirmation, request sent to `POST /api/query` with action "delete"
- Success message displayed
- Document removed from list

**Status:** ⬜ Not started | ⬜ In progress | ⬜ Completed | ⬜ Issues found

**Issues encountered:**
```
(Report any errors or unexpected behavior here)
```

---

## Step 8: Test Query Explorer

### 8.1 Navigate to Query Explorer

**Action:**
- Click "Query Explorer" in the sidebar

**Expected outcome:**
- URL changes to `http://localhost:8090/admin/#/query`
- Query editor page loads
- Collection dropdown, action dropdown, query editor visible

**Status:** ⬜ Not started | ⬜ In progress | ⬜ Completed | ⬜ Issues found

**Issues encountered:**
```
(Report any errors or unexpected behavior here)
```

### 8.2 Execute a find query

**Action:**
- Select collection: `test_users`
- Select action: `find`
- Enter query:
```json
{
  "where": {},
  "limit": 10
}
```
- Click "Execute Query"

**Expected outcome:**
- Request sent to `POST /api/query`
- Results displayed below (may be empty if no documents)
- Query history saved

**Status:** ⬜ Not started | ⬜ In progress | ⬜ Completed | ⬜ Issues found

**Issues encountered:**
```
(Report any errors or unexpected behavior here)
```

---

## Step 9: Test User Management

### 9.1 Navigate to Users page

**Action:**
- Click "Users" in the sidebar

**Expected outcome:**
- URL changes to `http://localhost:8090/admin/#/users`
- Users list page loads
- Shows existing users (may be empty)

**Status:** ⬜ Not started | ⬜ In progress | ⬜ Completed | ⬜ Issues found

**Issues encountered:**
```
(Report any errors or unexpected behavior here)
```

### 9.2 Create a test user

**Action:**
- Click "New User" button
- Enter email: `test@example.com`
- Enter password: `testpassword123`
- (Optional) Add metadata
- Click "Create User"

**Expected outcome:**
- Request sent to `POST /api/admin/users`
- Success message displayed
- New user appears in the list

**Status:** ⬜ Not started | ⬜ In progress | ⬜ Completed | ⬜ Issues found

**Issues encountered:**
```
(Report any errors or unexpected behavior here)
```

---

## Step 10: Test File Management

### 10.1 Navigate to Files page

**Action:**
- Click "Files" in the sidebar

**Expected outcome:**
- URL changes to `http://localhost:8090/admin/#/files`
- File browser page loads
- Shows empty state or existing files
- Upload button visible

**Status:** ⬜ Not started | ⬜ In progress | ⬜ Completed | ⬜ Issues found

**Issues encountered:**
```
(Report any errors or unexpected behavior here)
```

### 10.2 Upload a test file

**Action:**
- Click "Upload File" or drag & drop a small test file (e.g., a text file or image)
- Wait for upload to complete

**Expected outcome:**
- Upload progress shown
- Request sent to `POST /api/storage/upload`
- Success message displayed
- File appears in the list with metadata

**Status:** ⬜ Not started | ⬜ In progress | ⬜ Completed | ⬜ Issues found

**Issues encountered:**
```
(Report any errors or unexpected behavior here)
```

### 10.3 Download the file

**Action:**
- Click "Download" button on the uploaded file

**Expected outcome:**
- Request sent to `GET /api/storage/files/{id}`
- File downloads successfully
- File content matches uploaded file

**Status:** ⬜ Not started | ⬜ In progress | ⬜ Completed | ⬜ Issues found

**Issues encountered:**
```
(Report any errors or unexpected behavior here)
```

---

## Step 11: Test API Tester

### 11.1 Navigate to API Tester

**Action:**
- Click "API Tester" in the sidebar

**Expected outcome:**
- URL changes to `http://localhost:8090/admin/#/api-tester`
- API tester page loads
- Request builder form visible

**Status:** ⬜ Not started | ⬜ In progress | ⬜ Completed | ⬜ Issues found

**Issues encountered:**
```
(Report any errors or unexpected behavior here)
```

### 11.2 Test a GET request

**Action:**
- Method: `GET`
- Endpoint: `/api/admin/collections`
- Click "Send Request"

**Expected outcome:**
- Request sent successfully
- Response displayed with status 200
- Response body shows collections list
- Request saved to history

**Status:** ⬜ Not started | ⬜ In progress | ⬜ Completed | ⬜ Issues found

**Issues encountered:**
```
(Report any errors or unexpected behavior here)
```

---

## Step 12: Test Settings Page

### 12.1 Navigate to Settings

**Action:**
- Click "Settings" in the sidebar

**Expected outcome:**
- URL changes to `http://localhost:8090/admin/#/settings`
- Settings page loads with tabs:
  - Appearance
  - Preferences
  - System Info

**Status:** ⬜ Not started | ⬜ In progress | ⬜ Completed | ⬜ Issues found

**Issues encountered:**
```
(Report any errors or unexpected behavior here)
```

### 12.2 Toggle theme

**Action:**
- Click on "Appearance" tab
- Toggle between Light/Dark theme

**Expected outcome:**
- Theme changes immediately
- Preference saved to localStorage
- Theme persists on page refresh

**Status:** ⬜ Not started | ⬜ In progress | ⬜ Completed | ⬜ Issues found

**Issues encountered:**
```
(Report any errors or unexpected behavior here)
```

---

## Step 13: Test Logout

### 13.1 Logout

**Action:**
- Click "Logout" button (usually in navbar or user menu)

**Expected outcome:**
- Request sent to `POST /api/admin/logout`
- Tokens cleared from localStorage
- Redirect to login page
- Cannot access protected routes

**Status:** ⬜ Not started | ⬜ In progress | ⬜ Completed | ⬜ Issues found

**Issues encountered:**
```
(Report any errors or unexpected behavior here)
```

---

## Common Issues and Troubleshooting

### Issue: Static files not loading (404 errors)

**Symptoms:**
- Browser shows 404 for `/admin/assets/*` files
- Blank page or unstyled page

**Solutions:**
1. Verify build output exists:
   ```bash
   ls -la Sources/SwiftBase/Resources/Public/
   ```
2. Rebuild AdminUI:
   ```bash
   cd AdminUI && pnpm build
   ```
3. Check server logs for static file requests

---

### Issue: CORS errors

**Symptoms:**
- Console shows CORS policy errors
- API requests fail with CORS error

**Solutions:**
1. Verify CORSMiddleware is configured in App.swift
2. Check that middleware is applied before routes
3. Restart the backend server

---

### Issue: Authentication fails

**Symptoms:**
- Login returns 401 Unauthorized
- "Invalid credentials" message

**Solutions:**
1. Verify admin user exists in database
2. Check password is correct
3. Check server logs for authentication errors
4. Verify JWT secret is configured

---

### Issue: API calls fail with 403 Forbidden

**Symptoms:**
- Dashboard loads but API calls fail
- "Admin access required" errors

**Solutions:**
1. Verify JWT token includes `"type": "admin"`
2. Check token is being sent in Authorization header
3. Verify JWTMiddleware has `requireAdmin: true` for admin routes

---

### Issue: SPA routing doesn't work (404 on refresh)

**Symptoms:**
- Refreshing page on `/admin/#/collections` shows 404
- Direct navigation to routes fails

**Solutions:**
1. Verify StaticFileMiddleware serves index.html for SPA fallback
2. Check wildcard route is configured: `router.get("/admin/**", ...)`
3. Ensure hash-based routing is used (URLs should have `#`)

---

## Summary Checklist

After completing all tests, verify:

- ✅ AdminUI loads at `/admin/`
- ✅ Admin login works
- ✅ Dashboard displays correctly
- ✅ Collections CRUD works
- ✅ Documents CRUD works
- ✅ Query Explorer works
- ✅ User management works
- ✅ File upload/download works
- ✅ API Tester works
- ✅ Settings work
- ✅ Logout works
- ✅ Theme switching works
- ✅ SPA routing works (refresh doesn't break)

---

## Next Steps

Once all tests pass:
1. Document any issues found and fixes applied
2. Consider adding more test data
3. Test with production build
4. Add authentication flow improvements if needed
5. Consider adding admin user seeding/migration

---

## Notes

Use this section to track additional observations, questions, or ideas:

```
(Your notes here)
```
