# Fly Postgres 볼륨 확장 가이드

현재 Spreader 애플리케이션은 1 GB 볼륨으로 생성된 Postgres Flex 클러스터(`spreader-db`)를 사용합니다. Fly.io 의 **볼륨은 줄일 수 없고 늘리기만 가능**하므로, 추후 데이터가 증가했을 때 확장 절차를 숙지해 두어야 합니다.

---

## 1. 볼륨 확장 전 체크리스트

1. **디스크 사용량 확인**
   ```bash
   fly pg monitor -a spreader-db
   ```
2. 앱 트래픽 줄이기(선택)
   * 유지보수 모드 배포 또는 짧은 장애 허용 시간에 진행

---

## 2. 볼륨 확장 명령

Postgres Flex 클러스터는 `fly volumes extend` 가 아닌 **`fly postgres volume extend`** 로 확장합니다.

```bash
fly postgres volume extend \
  -a spreader-db \
  --volume-id <VOLUME_ID> \
  --size <NEW_SIZE_GB>
```

### 매개변수 설명
* `<VOLUME_ID>` – 확인 방법:
  ```bash
  fly volumes list -a spreader-db
  ```
* `<NEW_SIZE_GB>` – 1 GB 이상, 현재보다 커야 함(예: 5, 10, 20 GB …)

> 확장은 *오프라인 마이그레이션* 이 아니며, 데이터는 유지됩니다. 다만 수십 초의 재시작 시간이 발생할 수 있습니다.

---

## 3. 확장 후 검증

```bash
# 볼륨 크기 확인
fly volumes list -a spreader-db

# 앱 건강 상태 확인
fly status -a spreader
```

문제가 없다면 작업은 완료입니다.

---

## 4. 참고 링크
* Fly Docs – [Volume Management](https://fly.io/docs/reference/volumes/)
* Fly Docs – [Postgres Flex](https://fly.io/docs/postgres/flex/)
