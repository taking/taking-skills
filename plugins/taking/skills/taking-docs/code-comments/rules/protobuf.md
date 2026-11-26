# protobuf (필드, 메시지 주석 = wire 계약)

proto 필드 주석은 wire 계약입니다. 필드 번호, reserved, oneof, enum zero-value, JSON 이름 안정성, breaking change를 문서화합니다.

---

## 1. 필드 번호는 재사용하지 않습니다

삭제한 필드 번호를 재사용하면 구버전이 옛 의미로 디코딩합니다. reserved로 봉인하고 이유를 남깁니다.

```protobuf
// Bad: 3을 지우고 새 필드에 3을 다시 씀 — 구버전과 wire 충돌
message Envelope {
  string new_field = 3;
}

// Good: 번호와 이름을 reserved로 봉인
message Envelope {
  reserved 3;                 // was legacy_tenant (removed v1.4, semantics changed)
  reserved "legacy_tenant";
  string tenant = 6;
}
```

## 2. oneof, optional 의미를 밝힙니다

"설정 안 됨"과 "빈 값"이 다르면 명시합니다.

```protobuf
// Good
message ReconcileResult {
  // Exactly one is set. `error` present ⇒ reconcile failed and must be retried;
  // `applied` present ⇒ terminal success. Neither set is a protocol violation.
  oneof outcome {
    Applied applied = 1;
    ReconcileError error = 2;
  }
  // optional: absent means "controller did not observe generation yet",
  // distinct from observed_generation = 0.
  optional int64 observed_generation = 3;
}
```

## 3. enum zero-value는 UNSPECIFIED로 둡니다

proto3에서 0은 기본값이라 "미설정"과 구분되지 않습니다. 0을 의미 있는 값으로 쓰지 않습니다.

```protobuf
// Bad: 0이 RUNNING — 필드 누락과 구분 불가
enum Phase { RUNNING = 0; FAILED = 1; }

// Good: 0은 미지정 전용
enum Phase {
  // 0 = 미지정: 송신자가 phase를 채우지 않았다는 뜻. 상태로 해석 금지.
  PHASE_UNSPECIFIED = 0;
  PHASE_RUNNING = 1;
  PHASE_FAILED = 2;
}
```

## 4. JSON, wire 이름 안정성을 지킵니다

`json_name`이나 필드 이름은 JSON 소비자의 계약입니다. 리네임은 breaking change임을 남깁니다.

```protobuf
// Good
// Serialized as "eventType" in JSON (Kafka envelope contract). Renaming this
// field breaks every non-proto consumer that reads the topic. Do not rename.
string event_type = 2 [json_name = "eventType"];
```

## 5. breaking change 주의를 필드에 남깁니다

required화, 타입 변경, 번호 변경은 wire를 깹니다. 필드 옆에 경고합니다.

```protobuf
// Good
// Widening from int32 to int64 is wire-compatible for varint; narrowing is NOT.
// Never change this to a fixed-width type — existing payloads won't parse.
int64 offset = 5;
```
