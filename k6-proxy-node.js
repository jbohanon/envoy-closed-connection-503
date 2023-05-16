import http from "k6/http";
import { sleep } from "k6";
import { check } from "k6";

export const options = {
  vus: 1000,
  duration: "10s",
};

export default function () {
  const res = http.get(
    "http://localhost:8082"
  );
  sleep(5);
  check(res, {
    "is status 503": (r) => r.status === 503,
  });

  if (res.status == 503) {
    console.error(res.body);
  }
}
