# 1. Git 설치 (PowerShell 관리자 권한 권장)
winget install --id Git.Git -e --source winget

# -----------------------------------------------------------
# [중요] 설치 완료 후, 현재 열린 PowerShell 창을 닫고 다시 실행해 주세요!
# -----------------------------------------------------------

# 2. 설치 확인 및 사용자 등록
git --version
git config --global user.name "Your Name"
git config --global user.email "your-email@example.com"

# 3. 동기화 할 폴더를 놓을 경로로 이동
cd "your path"

# 4. 레포지토리 내려받기
git clone "https://github.com/sinsu0723/SoC_Design_and_Programming"