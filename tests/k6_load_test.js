import http from 'k6/http';
import { check, sleep } from 'k6';

// Performance targets:
// Target 100 -> 500 users, validating < 50ms p95 latency under load
export const options = {
  stages: [
    { duration: '30s', target: 100 },
    { duration: '1m', target: 500 },
    { duration: '30s', target: 0 },
  ],
  thresholds: {
    http_req_duration: ['p(95)<50'], // 95% of requests must complete below 50ms
    http_req_failed: ['rate<0.01'],   // Error rate should be less than 1%
  },
};

const BASE_URL = __ENV.TARGET_URL || 'http://localhost:8000';

export default function () {
  // 1. Create a short URL
  const shortenPayload = JSON.stringify({
    url: `https://example.com/test-load-${Math.random()}`,
  });
  const headers = { 'Content-Type': 'application/json' };

  const shortenRes = http.post(`${BASE_URL}/api/v1/shorten`, shortenPayload, { headers });
  const shortenOk = check(shortenRes, {
    'shorten status is 201': (r) => r.status === 201,
  });

  if (shortenOk) {
    const data = shortenRes.json();
    const shortCode = data.short_code;

    // 2. Fetch redirect (testing cache-aside read performance)
    const redirectRes = http.get(`${BASE_URL}/${shortCode}`, {
      redirects: 0,
    });
    check(redirectRes, {
      'redirect status is 302': (r) => r.status === 302,
      'has location header': (r) => r.headers['Location'] !== undefined,
    });
  }

  sleep(0.1);
}
