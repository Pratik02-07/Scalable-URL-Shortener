import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  stages: [
    { duration: '5s', target: 20 },
    { duration: '10s', target: 50 },
    { duration: '5s', target: 0 },
  ],
  thresholds: {
    http_req_duration: ['p(95)<100'],
    http_req_failed: ['rate<0.05'],
  },
};

const BASE_URL = __ENV.TARGET_URL || 'http://localhost:8000';

export default function () {
  const payload = JSON.stringify({
    url: `https://example.com/test-${Date.now()}-${__VU}-${__ITER}`,
  });
  const headers = { 'Content-Type': 'application/json' };

  const shortenRes = http.post(`${BASE_URL}/api/v1/shorten`, payload, { headers });
  const shortenOk = check(shortenRes, {
    'shorten status is 201': (r) => r.status === 201,
  });

  if (shortenOk) {
    const data = shortenRes.json();
    const shortCode = data.short_code;

    const redirectRes = http.get(`${BASE_URL}/${shortCode}`, {
      redirects: 0,
    });
    check(redirectRes, {
      'redirect status is 302': (r) => r.status === 302,
    });
  }

  sleep(0.05);
}
