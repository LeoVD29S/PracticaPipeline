import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  vus: 10,
  duration: '20s',
  thresholds: {
    http_req_failed: ['rate<0.05'],
    http_req_duration: ['p(95)<800'],
  },
};

export default function () {
  const home = http.get(`${__ENV.BASE_URL || 'http://127.0.0.1:8000'}/`);
  const catalog = http.get(`${__ENV.BASE_URL || 'http://127.0.0.1:8000'}/cartas`);
  const api = http.get(`${__ENV.BASE_URL || 'http://127.0.0.1:8000'}/api/cards`);

  check(home, { 'inicio 200': (r) => r.status === 200 });
  check(catalog, { 'catalogo 200': (r) => r.status === 200 });
  check(api, { 'api 200': (r) => r.status === 200 });
  sleep(1);
}
