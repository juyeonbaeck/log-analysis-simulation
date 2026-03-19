#!/bin/bash
# ============================================================
# monitor_attack.sh
# Apache Struts RCE (CVE-2017-5638) 실시간 탐지 스크립트
# 실행 주기: crontab 1분마다 자동 실행
# ============================================================

LOG_PATH="/app/payment-system/logs/access.log"
ALERT_FILE="/app/payment-system/logs/attack_alerts.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# ------------------------------------------------------------
# [1] OGNL / java.lang 패턴 탐지 (Struts RCE 공격 시그니처)
# ------------------------------------------------------------
OGNL_HIT=$(grep -icE "java\.lang|ognl" "$LOG_PATH")

if [ "$OGNL_HIT" -gt 0 ]; then
    echo "[$TIMESTAMP] [CRITICAL] OGNL 인젝션 탐지: ${OGNL_HIT}건" >> "$ALERT_FILE"
    grep -iE "java\.lang|ognl" "$LOG_PATH" >> "$ALERT_FILE"
    echo "---" >> "$ALERT_FILE"
fi

# ------------------------------------------------------------
# [2] 대용량 응답 탐지 (10MB 이상 — 데이터 유출 가능성)
# ------------------------------------------------------------
awk -v ts="$TIMESTAMP" '$10 > 10485760 {
    print "[" ts "] [WARNING] Large Response Detected: " $0
}' "$LOG_PATH" >> "$ALERT_FILE"

# ------------------------------------------------------------
# [3] 동일 IP 500 에러 다수 발생 탐지 (5회 이상)
# ------------------------------------------------------------
awk '$9 == 500 {print $1}' "$LOG_PATH" \
    | sort | uniq -c \
    | awk -v ts="$TIMESTAMP" '$1 >= 5 {
        print "[" ts "] [WARNING] 500 Error Spike — IP: " $2 " (" $1 "회)"
    }' >> "$ALERT_FILE"

# ------------------------------------------------------------
# [4] 공격자 IP 반복 접근 탐지 (분당 10회 이상)
# ------------------------------------------------------------
CURRENT_MIN=$(date '+%H:%M')
grep "$CURRENT_MIN" "$LOG_PATH" \
    | awk '{print $1}' \
    | sort | uniq -c \
    | awk -v ts="$TIMESTAMP" '$1 >= 10 {
        print "[" ts "] [WARNING] Rapid Request — IP: " $2 " (" $1 "req/min)"
    }' >> "$ALERT_FILE"

# ------------------------------------------------------------
# [5] /tmp 디렉토리 내 실행 파일 탐지 (백도어 탐지)
# ------------------------------------------------------------
BACKDOOR=$(find /tmp -type f -executable 2>/dev/null)

if [ -n "$BACKDOOR" ]; then
    echo "[$TIMESTAMP] [CRITICAL] /tmp 실행 파일 탐지:" >> "$ALERT_FILE"
    echo "$BACKDOOR" >> "$ALERT_FILE"
    echo "---" >> "$ALERT_FILE"
fi

# ------------------------------------------------------------
# [6] 최종 알림 출력
# ------------------------------------------------------------
if [ -s "$ALERT_FILE" ]; then
    echo "[$TIMESTAMP] ALERT: 보안 이벤트 탐지 — $ALERT_FILE 확인 요망."
else
    echo "[$TIMESTAMP] OK: 이상 징후 없음."
fi
