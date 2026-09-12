"""
gpt51_client.py - Cliente Azure OpenAI GPT-5.1 Responses API
Reemplaza al cliente Chat Completions de v5.3.
Responses API es el nuevo primitivo (superset de Chat Completions).
"""
import os, json, logging, time, requests

log = logging.getLogger(__name__)

AZURE_ENDPOINT = os.getenv("GPT51_ENDPOINT", "https://dev-aif-chat-ai-postventa.cognitiveservices.azure.com")
API_KEY = os.getenv("GPT51_API_KEY", "")
DEPLOYMENT = os.getenv("GPT51_DEPLOYMENT", "gpt-5.1-chat")
API_VERSION = os.getenv("GPT51_API_VERSION", "2025-04-01-preview")


class GPT51Client:
    def __init__(self, endpoint=None, api_key=None, deployment=None):
        self.endpoint = (endpoint or AZURE_ENDPOINT).rstrip("/")
        self.api_key = api_key or API_KEY
        self.deployment = deployment or DEPLOYMENT
        if not self.api_key:
            raise ValueError("GPT51_API_KEY no configurado")

    def responses_create(self, system_prompt, user_input, max_tokens=2048, temperature=0.1, timeout=60):
        url = f"{self.endpoint}/openai/responses?api-version={API_VERSION}"
        payload = {
            "model": self.deployment,
            "input": [
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_input}
            ],
            "max_output_tokens": max_tokens,
            "temperature": temperature
        }
        headers = {
            "Content-Type": "application/json",
            "api-key": self.api_key
        }
        last_exc = None
        for attempt in range(3):
            try:
                r = requests.post(url, json=payload, headers=headers, timeout=timeout)
                r.raise_for_status()
                data = r.json()
                text = self._extract_text(data)
                return {"text": text, "raw": data, "usage": data.get("usage", {})}
            except Exception as e:
                last_exc = e
                log.warning(f"GPT-5.1 attempt {attempt+1}/3 failed: {e}")
                if attempt < 2:
                    time.sleep(2 * (attempt + 1))
        raise RuntimeError(f"GPT-5.1 fallo tras 3 intentos: {last_exc}")

    @staticmethod
    def _extract_text(data):
        if "output_text" in data:
            return data["output_text"]
        for item in data.get("output", []):
            if item.get("type") == "message":
                for c in item.get("content", []):
                    if c.get("type") in ("output_text", "text"):
                        return c.get("text", "")
        if "choices" in data:
            return data["choices"][0].get("message", {}).get("content", "")
        return json.dumps(data)

    def ask_json(self, system_prompt, user_input, **kwargs):
        result = self.responses_create(system_prompt, user_input, **kwargs)
        text = result["text"].strip()
        if text.startswith("```"):
            text = text.split("```", 2)[1]
            if text.startswith("json"):
                text = text[4:]
            text = text.strip().rstrip("`").strip()
        try:
            return json.loads(text), result["usage"]
        except Exception as e:
            log.error(f"JSON parse failed: {e} | text={text[:300]}")
            raise
