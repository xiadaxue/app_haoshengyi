## 3. API 设计

### 3.0 API设计规范

#### 3.1.1 RESTful API 设计原则

- **资源命名**：使用名词复数形式表示资源集合（如 `/transactions`）
- **HTTP 方法**：使用标准 HTTP 方法表示操作
  - GET：获取资源
  - POST：创建资源
  - PUT：全量更新资源
  - PATCH：部分更新资源
  - DELETE：删除资源
- **状态码**：使用标准 HTTP 状态码表示操作结果
  - 2xx：成功
  - 4xx：客户端错误
  - 5xx：服务器错误
- **版本控制**：在 URL 中包含版本号（如 `/api/v1/transactions`）
- **分页**：使用 `page` 和 `pageSize` 参数进行分页
- **过滤**：使用查询参数进行过滤（如 `/transactions?type=income`）
- **排序**：使用 `sort` 参数进行排序（如 `/transactions?sort=date:desc`）
- **字段选择**：使用 `fields` 参数选择返回字段（如 `/transactions?fields=id,amount,date`）

#### 3.1.2 API 响应格式

所有 API 响应使用统一的 JSON 格式：

成功响应：
```json
{
    "code": 200,           // 业务状态码
    "message": "成功",    // 状态描述
    "data": {             // 业务数据
        // 具体业务数据
    }
}
```

错误响应：
```json
{
    "code": 400,           // 业务错误码
    "message": "参数错误", // 错误描述
    "data": null,         // 通常为 null
    "errors": [           // 详细错误信息（可选）
        {
            "field": "amount",
            "message": "金额必须大于0"
        }
    ]
}
```

---

### 3.2 用户认证 API

#### 3.2.1 用户注册

- **路径**：`/api/v1/auth/register`
- **方法**：POST
- **请求参数**：
  ```json
  {
    "phone": "13800138000",         // 手机号码，必填，长度11位
    "verificationCode": "123456",   // 验证码，必填，长度6位
    "nickname": "用户昵称"          // 用户昵称，可选，最大长度50字符
  }
  ```
- **响应格式**：
  ```json
  {
    "code": 200,
    "message": "注册成功",
    "data": {
      "userId": "用户ID",
      "token": "JWT令牌",
      "expiresIn": 604800,        // 过期时间（秒），7天
      "userInfo": {
        "nickname": "用户昵称",
        "avatar": "头像URL",
        "phone": "13800138000"
      }
    }
  }
  ```

#### 3.2.2 发送验证码

- **路径**：`/api/v1/auth/sendVerificationCode`
- **方法**：POST
- **请求参数**：
  ```json
  {
    "phone": "13800138000"  // 手机号码，必填，长度11位
  }
  ```
- **响应格式**：
  ```json
  {
    "code": 200,
    "message": "验证码已发送",
    "data": {
      "expire_time": "5分钟",
      "code": "123456"      // 验证码，仅在开发环境返回
    }
  }
  ```

#### 3.2.3 用户登录

- **路径**：`/api/v1/auth/login`
- **方法**：POST
- **请求参数**：
  ```json
  {
    "phone": "13800138000",         // 手机号码，必填，长度11位
    "verificationCode": "123456"    // 验证码，必填，长度6位
  }
  ```
- **响应格式**：
  ```json
  {
    "code": 200,
    "message": "登录成功",
    "data": {
      "userId": "用户ID",
      "token": "JWT令牌",
      "expiresIn": 604800,        // 过期时间（秒），7天
      "userInfo": {
        "nickname": "用户昵称",
        "avatar": "头像URL",
        "phone": "13800138000"
      }
    }
  }
  ```

---

### 3.3 用户信息 API

#### 3.3.1 获取用户信息

- **路径**：`/api/v1/user/userInfo`
- **方法**：GET
- **请求头**：
  - `Authorization` (string)：JWT令牌，格式为 `Bearer {token}`
- **响应格式**：
  ```json
  {
    "code": 200,
    "message": "获取成功",
    "data": {
      "id": 10001,
      "phone": "13800138000",
      "nickname": "用户昵称",
      "avatar": "头像URL",
      "created_at": "2023-01-01T12:00:00Z",
      "updated_at": "2023-01-01T12:00:00Z",
      "last_login_at": "2023-01-01T12:00:00Z"
    }
  }
  ```

#### 3.3.2 更新用户信息

- **路径**：`/api/v1/user/userInfo`
- **方法**：PUT
- **请求头**：
  - `Authorization` (string)：JWT令牌，格式为 `Bearer {token}`
- **请求参数**：
  ```json
  {
    "nickname": "新昵称",                            // 可选，最大长度50字符
    "avatar": "https://example.com/avatar.jpg"      // 可选，必须是有效的URL
  }
  ```
- **响应格式**：
  ```json
  {
    "code": 200,
    "message": "更新成功",
    "data": null
  }
  ```

---

### 3.4 账单记录 API

#### 3.4.1 创建账单记录

- **路径**：`/api/v1/transactions`
- **方法**：POST
- **请求头**：
  - `Authorization` (string)：JWT令牌，格式为 `Bearer {token}`
- **请求参数**：
  ```json
  {
    "type": "income",                     // 交易类型，必填，取值：income(收入)、expense(支出)、borrow(借用)、return(归还)、settle(结算)
    "amount": 100.50,                     // 金额，必填，大于0
    "transaction_date": "2023-03-15T00:00:00Z", // 交易日期，必填
    "remark": "备注信息",                 // 备注，可选
    "users": ["老李", "小王"],            // 用户列表，必填
    "products": [                         // 产品列表，可选
      {
        "name": "千叶",
        "quantity": 5000,
        "unit": "盆",
        "unit_price": 2.0
      }
    ],
    "containers": [                       // 容器列表，可选
      {
        "name": "筐",
        "quantity": 100
      }
    ],
    "category": "销售",                   // 分类，必填
    "description": "描述信息",            // 描述，可选
    "tags": ["标签1", "标签2"]            // 标签列表，可选
  }
  ```
- **响应格式**：
  ```json
  {
    "code": 200,
    "message": "创建成功",
    "data": {
      "transactionId": "c8f9c48a-1b9a-4e5c-8f4b-d1e2f3a4b5c6",
      "createdAt": "2023-03-15T08:30:00Z"
    }
  }
  ```

#### 3.4.2 获取账单记录详情

- **路径**：`/api/v1/transactions/:id`
- **方法**：GET
- **请求头**：
  - `Authorization` (string)：JWT令牌，格式为 `Bearer {token}`
- **路径参数**：
  - `id` (string)：账单记录ID，必填
- **响应格式**：
  ```json
  {
    "code": 200,
    "message": "获取成功",
    "data": {
      "transactionId": "c8f9c48a-1b9a-4e5c-8f4b-d1e2f3a4b5c6",
      "type": "income",
      "amount": 100.50,
      "transactionDate": "2023-03-15T00:00:00Z",
      "remark": "备注信息",
      "users": ["老李", "小王"],
      "products": [
        {
          "name": "千叶",
          "quantity": 5000,
          "unit": "盆",
          "unit_price": 2.0
        }
      ],
      "containers": [
        {
          "name": "筐",
          "quantity": 100
        }
      ],
      "category": "销售",
      "description": "描述信息",
      "tags": ["标签1", "标签2"],
      "createdAt": "2023-03-15T08:30:00Z",
      "updatedAt": "2023-03-15T08:30:00Z"
    }
  }
  ```

#### 3.4.3 更新账单记录

- **路径**：`/api/v1/transactions/:id`
- **方法**：PUT
- **请求头**：
  - `Authorization` (string)：JWT令牌，格式为 `Bearer {token}`
- **路径参数**：
  - `id` (string)：账单记录ID，必填
- **请求参数**：
  ```json
  {
    "type": "expense",                       // 交易类型，可选
    "amount": 200.00,                        // 金额，可选，大于0
    "transaction_date": "2023-03-16T00:00:00Z", // 交易日期，可选
    "remark": "更新的备注",                  // 备注，可选
    "users": ["老李", "小张"],               // 用户列表，可选
    "products": [                           // 产品列表，可选
      {
        "name": "月季",
        "quantity": 3000,
        "unit": "盆",
        "unit_price": 1.5
      }
    ],
    "containers": [                         // 容器列表，可选
      {
        "name": "箱",
        "quantity": 50
      }
    ],
    "category": "采购",                      // 分类，可选
    "description": "更新的描述",             // 描述，可选
    "tags": ["标签3", "标签4"]               // 标签列表，可选
  }
  ```
- **响应格式**：
  ```json
  {
    "code": 200,
    "message": "更新成功",
    "data": null
  }
  ```

#### 3.4.4 删除账单记录

- **路径**：`/api/v1/transactions/:id`
- **方法**：DELETE
- **请求头**：
  - `Authorization` (string)：JWT令牌，格式为 `Bearer {token}`
- **路径参数**：
  - `id` (string)：账单记录ID，必填
- **响应格式**：
  ```json
  {
    "code": 200,
    "message": "删除成功",
    "data": null
  }
  ```

#### 3.4.5 获取账单记录列表

- **路径**：`/api/v1/transactions`
- **方法**：GET
- **请求头**：
  - `Authorization` (string)：JWT令牌，格式为 `Bearer {token}`
- **查询参数**：
  - `page` (int)：页码，默认为1
  - `pageSize` (int)：每页数量，默认为10
  - `startDate` (string)：开始日期，格式为YYYY-MM-DD
  - `endDate` (string)：结束日期，格式为YYYY-MM-DD
  - `type` (string)：交易类型，可选值：income、expense、borrow、return、settle
  - `category` (string)：分类
  - `keyword` (string)：关键词，用于搜索备注、描述等字段
  - `tag` (string)：标签
  - `sort` (string)：排序字段，默认为交易日期降序
- **响应格式**：
  ```json
  {
    "code": 200,
    "message": "获取成功",
    "data": {
      "total": 150,
      "page": 1,
      "pageSize": 10,
      "transactions": [
        {
          "transactionId": "c8f9c48a-1b9a-4e5c-8f4b-d1e2f3a4b5c6",
          "type": "income",
          "amount": 100.50,
          "transactionDate": "2023-03-15T00:00:00Z",
          "remark": "备注信息",
          "users": ["老李", "小王"],
          "products": [
            {
              "name": "千叶",
              "quantity": 5000,
              "unit": "盆",
              "unit_price": 2.0
            }
          ],
          "containers": [
            {
              "name": "筐",
              "quantity": 100
            }
          ],
          "category": "销售",
          "description": "描述信息",
          "tags": ["标签1", "标签2"],
          "createdAt": "2023-03-15T08:30:00Z",
          "updatedAt": "2023-03-15T08:30:00Z"
        },
        // ... 更多交易记录
      ]
    }
  }
  ```

### 3.5 智能记账 API

#### 3.5.1 文本记账解析

- **路径**：`/api/v1/accounting/text`
- **方法**：POST
- **请求头**：
  - `Authorization` (string)：JWT令牌，格式为 `Bearer {token}`
- **请求参数**：
  ```json
  {
    "text": "老李买了5000盆千叶共10000元"  // 待解析的文本内容
  }
  ```
- **响应格式**：
  ```json
  {
    "code": 200,
    "message": "成功",
    "data": {
      "type": "expense",
      "users": ["老李"],
      "products": [
        {
          "name": "千叶",
          "quantity": 5000,
          "unit": "盆",
          "unit_price": 2
        }
      ],
      "amount": 10000,
      "date": "2023-03-15",
      "remark": "老李购买千叶"
    }
  }
  ```

#### 3.5.2 语音记账上传与解析

- **路径**：`/api/v1/accounting/voice`
- **方法**：POST
- **请求头**：
  - `Authorization` (string)：JWT令牌，格式为 `Bearer {token}`
- **请求参数**：
  - `file` (file)：音频文件
  - `duration` (int)：音频时长（秒）
- **响应格式**：
  ```json
  {
    "code": 200,
    "message": "成功",
    "data": {
      "result": {
        "type": "income",
        "users": ["老李"],
        "products": [
          {
            "name": "千叶",
            "quantity": 5000,
            "unit": "盆",
            "unit_price": 2
          }
        ],
        "amount": 10000,
        "date": "2023-03-15",
        "remark": "老李购买千叶"
      },
      "file_path": "/uploads/voice/10001_1679123456.mp3",
      "text": "卖给老李5000盆千叶，一共10000元"
    }
  }
  ```

### 3.6 语音记录 API

#### 3.6.1 上传语音

- **路径**：`/api/v1/voice/upload`
- **方法**：POST
- **请求头**：
  - `Authorization` (string)：JWT令牌，格式为 `Bearer {token}`
- **请求参数**：
  - `audio` (file)：音频文件
  - `duration` (int)：音频时长（秒）
- **响应格式**：
  ```json
  {
    "code": 200,
    "message": "处理成功",
    "data": {
      "voiceId": 10001,
      "text": "卖给老李5000盆千叶，一共10000元",
      "parsedData": {
        "type": "income",
        "users": ["老李"],
        "products": [
          {
            "name": "千叶",
            "quantity": 5000,
            "unit": "盆",
            "unit_price": 2
          }
        ],
        "amount": 10000,
        "date": "2023-03-15",
        "remark": "卖给老李千叶"
      },
      "createdAt": "2023-03-15T08:30:00Z"
    }
  }
  ```

#### 3.6.2 获取语音记录列表

- **路径**：`/api/v1/voice/records`
- **方法**：GET
- **请求头**：
  - `Authorization` (string)：JWT令牌，格式为 `Bearer {token}`
- **响应格式**：
  ```json
  {
    "code": 200,
    "message": "获取成功",
    "data": {
      "records": [
        {
          "id": 10001,
          "file_path": "/uploads/voice/10001_1679123456.mp3",
          "duration": 5,
          "text": "卖给老李5000盆千叶，一共10000元",
          "transaction_id": "c8f9c48a-1b9a-4e5c-8f4b-d1e2f3a4b5c6",
          "created_at": "2023-03-15T08:30:00Z"
        }
        // ... 更多语音记录
      ]
    }
  }
  ```
