import "dotenv/config";
import express from "express";
import cors from "cors";
import path from "path";
import { fileURLToPath } from "url";

const app = express();
app.use(cors());
app.use(express.json({ limit: "15mb" }));

const __dirname = path.dirname(fileURLToPath(import.meta.url));
app.use(express.static(path.join(__dirname, "../public")));

const port = process.env.PORT || 3000;
const openAiKey = process.env.OPENAI_API_KEY || "";
const openAiModel = process.env.OPENAI_MODEL || "gpt-4.1-mini";
const openAiBaseUrl =
  process.env.OPENAI_BASE_URL || "https://api.openai.com/v1/responses";

app.get("/health", (_req, res) => {
  res.json({ ok: true });
});

app.post("/analyze", async (req, res) => {
  try {
    const { texts = [], metadata = {}, images = [] } = req.body || {};
    const textList = Array.isArray(texts) ? texts : [];
    const imageList = Array.isArray(images) ? images : [];
    if (textList.length === 0 && imageList.length === 0) {
      return res.status(400).json({ error: "texts 或 images 不能为空" });
    }

    const requestKey = (req.get("x-openai-key") || "").trim();
    const effectiveKey = requestKey || openAiKey;
    const result = effectiveKey
      ? await analyzeWithOpenAI(textList, imageList, metadata, effectiveKey)
      : fallbackAnalyze(textList, imageList);

    res.json(result);
  } catch (error) {
    res.status(500).json({ error: error?.message || "分析失败" });
  }
});

app.listen(port, () => {
  console.log(`Server running on http://localhost:${port}`);
});

async function analyzeWithOpenAI(texts, images, metadata, apiKey) {
  const prompt = [
    "你是信息整理助手。请根据截图 OCR 文本进行整理。",
    "只返回 JSON，格式如下：",
    "{",
    '  "summary": "整体摘要",',
    '  "similarities": ["相似点1", "相似点2"],',
    '  "trends": ["趋势1", "趋势2"]',
    "}",
    "不要输出额外文本。",
    "",
    "输入文本：",
    texts.length
      ? texts.map((t, i) => `#${i + 1}\n${t}`).join("\n\n")
      : "（无手动文本，以下为图片）",
    "",
    "元数据：",
    JSON.stringify(metadata)
  ].join("\n");

  const endpoint = buildOpenAiEndpoint(openAiBaseUrl);
  const isChatCompletions = endpoint.endsWith("/v1/chat/completions");

  let body;
  if (isChatCompletions) {
    body = {
      model: openAiModel,
      messages: [{ role: "user", content: prompt }],
      temperature: 0.2,
      max_tokens: 400
    };
  } else {
    const content = [{ type: "input_text", text: prompt }];
    for (const img of images) {
      if (img?.dataUrl) {
        content.push({ type: "input_image", image_url: img.dataUrl });
      }
    }
    body = {
      model: openAiModel,
      input: [{ role: "user", content }],
      max_output_tokens: 400
    };
  }

  const response = await fetch(endpoint, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${apiKey}`
    },
    body: JSON.stringify(body)
  });

  if (!response.ok) {
    const text = await response.text();
    throw new Error(`OpenAI 请求失败: ${text}`);
  }

  const data = await response.json();
  const outputText =
    data.output_text ||
    data.output?.[0]?.content?.[0]?.text ||
    data.choices?.[0]?.message?.content ||
    "";

  const parsed = safeParseJSON(outputText);
  if (!parsed) {
    throw new Error("OpenAI 返回内容无法解析为 JSON");
  }

  return {
    summary: parsed.summary || "",
    similarities: parsed.similarities || [],
    trends: parsed.trends || []
  };
}

function buildOpenAiEndpoint(value) {
  const trimmed = (value || "").trim().replace(/\/$/, "");
  if (!trimmed) {
    return "https://api.openai.com/v1/responses";
  }
  if (trimmed.endsWith("/v1/chat/completions")) {
    return trimmed;
  }
  if (trimmed.endsWith("/v1/responses")) {
    return trimmed;
  }
  return `${trimmed}/v1/responses`;
}

function fallbackAnalyze(texts, images) {
  if (images.length > 0 && texts.length === 0) {
    return {
      summary: "未配置 OpenAI，无法解析图片内容。",
      similarities: [],
      trends: []
    };
  }
  const joined = texts.join("\n");
  const words = joined
    .replace(/[^\u4e00-\u9fa5a-zA-Z0-9\s]/g, " ")
    .split(/\s+/)
    .filter((w) => w.length > 1);

  const counts = new Map();
  for (const w of words) {
    counts.set(w, (counts.get(w) || 0) + 1);
  }
  const top = Array.from(counts.entries())
    .sort((a, b) => b[1] - a[1])
    .slice(0, 5)
    .map(([w]) => w);

  return {
    summary: "未配置 OpenAI，返回本地关键词摘要。",
    similarities: top.length ? ["高频关键词: " + top.join(", ")] : [],
    trends: []
  };
}

function safeParseJSON(text) {
  if (!text) return null;
  const start = text.indexOf("{");
  const end = text.lastIndexOf("}");
  if (start === -1 || end === -1 || end <= start) return null;
  try {
    return JSON.parse(text.slice(start, end + 1));
  } catch {
    return null;
  }
}
