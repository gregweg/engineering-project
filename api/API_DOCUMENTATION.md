# Bookkeeping API Documentation

## Base URL
```
http://localhost:3000/v1
```

## Authentication
Currently uses a basic user system. Authentication will be added in future versions.

---

## Transactions API

### GET /transactions
**Description**: List all transactions with pagination

**Parameters**:
- `limit` (optional): Number of transactions to return (default: 100)

**Response**:
```json
[
  {
    "id": 1,
    "date": "2025-09-17",
    "description": "Walmart 8104",
    "amount": "128.80",
    "needs_review": false,
    "category": {
      "id": 1,
      "name": "Shopping"
    }
  }
]
```

### GET /transactions/:id
**Description**: Get a specific transaction with detailed information

**Response**:
```json
{
  "id": 1,
  "date": "2025-09-17",
  "description": "Walmart 8104",
  "amount": "128.80",
  "needs_review": false,
  "fingerprint": "abc123...",
  "metadata": {
    "import": {
      "source_file": "transactions.csv",
      "rownum": 1
    }
  },
  "created_at": "2025-09-22T10:30:00Z",
  "updated_at": "2025-09-22T10:30:00Z",
  "category": {
    "id": 1,
    "name": "Shopping",
    "color": "#ff5722"
  },
  "anomalies": [
    {
      "id": 1,
      "flag_type": "duplicate",
      "details": {
        "message": "Potential duplicate transaction"
      },
      "resolved": false,
      "created_at": "2025-09-22T10:30:00Z"
    }
  ]
}
```

### POST /transactions
**Description**: Create a new transaction

**Request Body**:
```json
{
  "transaction": {
    "date": "2025-09-22",
    "description": "Coffee Shop",
    "amount": "4.50",
    "category_id": 2,
    "metadata": {}
  }
}
```

**Response**: 201 Created
```json
{
  "id": 2,
  "date": "2025-09-22",
  "description": "Coffee Shop",
  "amount": "4.50",
  "needs_review": false,
  "category": {
    "id": 2,
    "name": "Food"
  }
}
```

### PATCH/PUT /transactions/:id
**Description**: Update an existing transaction

**Request Body**:
```json
{
  "transaction": {
    "description": "Updated description",
    "category_id": 3
  }
}
```

### DELETE /transactions/:id
**Description**: Delete a specific transaction

**Response**: 204 No Content

---

## Bulk Transaction Operations

### POST /transactions/bulk_update
**Description**: Bulk update transactions (categorization)

**Request Body**:
```json
{
  "ids": [1, 2, 3],
  "category_name": "Shopping"
}
```

### POST /transactions/bulk_flag
**Description**: Flag multiple transactions for review

**Request Body**:
```json
{
  "ids": [1, 2, 3]
}
```

### POST /transactions/bulk_unflag
**Description**: Remove flags from multiple transactions

**Request Body**:
```json
{
  "ids": [1, 2, 3]
}
```

### POST /transactions/bulk_destroy
**Description**: Delete multiple transactions

**Request Body**:
```json
{
  "ids": [1, 2, 3]
}
```

---

## Transaction Flags

### PATCH /transactions/:id/flag
**Description**: Flag a transaction for review

### PATCH /transactions/:id/unflag
**Description**: Remove flag from a transaction

### PATCH /transactions/:id/flag_type
**Description**: Add a specific flag type to a transaction

**Request Body**:
```json
{
  "flag_type": "duplicate",
  "message": "Duplicate transaction found"
}
```

### PATCH /transactions/:id/unflag_type
**Description**: Remove a specific flag type from a transaction

**Request Body**:
```json
{
  "flag_type": "duplicate"
}
```

### GET /transactions/flags
**Description**: Get flags for transactions

**Parameters**:
- `ids[]` (optional): Array of transaction IDs

**Response**:
```json
[
  {
    "id": 1,
    "flags": [
      {
        "type": "duplicate",
        "message": "Potential duplicate transaction"
      }
    ]
  }
]
```

---

## Categories API

### GET /categories
**Description**: List all categories

**Response**:
```json
[
  {
    "id": 1,
    "name": "Shopping",
    "color": "#ff5722",
    "created_at": "2025-09-22T10:30:00Z",
    "updated_at": "2025-09-22T10:30:00Z"
  }
]
```

### GET /categories/:id
**Description**: Get a specific category with associated transactions

**Response**:
```json
{
  "id": 1,
  "name": "Shopping",
  "color": "#ff5722",
  "created_at": "2025-09-22T10:30:00Z",
  "updated_at": "2025-09-22T10:30:00Z",
  "transactions": [
    {
      "id": 1,
      "date": "2025-09-17",
      "description": "Walmart 8104",
      "amount": "128.80"
    }
  ]
}
```

### POST /categories
**Description**: Create a new category

**Request Body**:
```json
{
  "category": {
    "name": "Entertainment",
    "color": "#9c27b0"
  }
}
```

**Response**: 201 Created

### PATCH/PUT /categories/:id
**Description**: Update a category

**Request Body**:
```json
{
  "category": {
    "name": "Updated Category Name",
    "color": "#2196f3"
  }
}
```

### DELETE /categories/:id
**Description**: Delete a category

**Response**:
```json
{
  "message": "Category deleted successfully",
  "transactions_affected": 5
}
```

---

## Rules API

### GET /rules
**Description**: List all automation rules

**Response**:
```json
[
  {
    "id": 1,
    "field": "description",
    "operator": "contains",
    "value": "Amazon",
    "action_type": "categorize",
    "action_value": "Shopping",
    "priority": 1,
    "enabled": true,
    "created_at": "2025-09-22T10:30:00Z",
    "updated_at": "2025-09-22T10:30:00Z"
  }
]
```

### GET /rules/:id
**Description**: Get a specific rule

### POST /rules
**Description**: Create a new automation rule

**Request Body**:
```json
{
  "rule": {
    "field": "description",
    "operator": "contains",
    "value": "Starbucks",
    "action_type": "categorize",
    "action_value": "Food",
    "priority": 2,
    "enabled": true
  }
}
```

### PATCH/PUT /rules/:id
**Description**: Update a rule

### DELETE /rules/:id
**Description**: Delete a rule

**Response**:
```json
{
  "message": "Rule deleted successfully"
}
```

---

## CSV Import API

### POST /transactions/import_csv
**Description**: Import transactions from CSV file

**Request**: Multipart form data with file upload

**Response**:
```json
{
  "total_rows": 100,
  "inserted": 95,
  "flagged": 5,
  "errors": [
    "Row 10: Invalid date format",
    "Row 25: Missing amount"
  ]
}
```

---

## Error Responses

### 400 Bad Request
```json
{
  "error": "Missing required parameters"
}
```

### 404 Not Found
```json
{
  "error": "Transaction not found"
}
```

### 422 Unprocessable Entity
```json
{
  "errors": [
    "Name can't be blank",
    "Amount must be a number"
  ]
}
```

### 500 Internal Server Error
```json
{
  "error": "Internal server error"
}
```

---

## Available Flag Types

- `duplicate`: Potential duplicate transaction
- `unusual_amount`: Amount is significantly different from typical transactions
- `missing_metadata`: Required information is missing
- `manual`: Manually flagged by user

---

## Available Rule Operators

- `contains`: Field contains the specified value
- `equals`: Field exactly equals the specified value
- `starts_with`: Field starts with the specified value
- `ends_with`: Field ends with the specified value
- `greater_than`: Numeric field is greater than the specified value
- `less_than`: Numeric field is less than the specified value

---

## Available Rule Actions

- `categorize`: Assign a category to the transaction
- `flag`: Mark the transaction for review
- `unflag`: Remove review flag from the transaction