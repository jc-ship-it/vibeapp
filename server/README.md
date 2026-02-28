Server 使用说明
=============

用途
----
接收 OCR 文本，返回摘要、相似点与趋势分析。

启动
----
1. 安装依赖：
   - `npm install`
2. 复制环境变量：
   - `cp .env.example .env`
3. 填写 `OPENAI_API_KEY`。
4. 启动服务：
   - `npm run dev`

接口
----
- `GET /health`：健康检查
- `POST /analyze`
  - 请求体：
    - `texts`: string[]
    - `metadata`: object (可选)
  - 响应：
    - `summary`: string
    - `similarities`: string[]
    - `trends`: string[]
