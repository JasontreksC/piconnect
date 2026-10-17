# piconnect

[English](README.en.md)

여러 이미지를 한 방향으로 이어 붙이는 macOS용 도구입니다. Swift로 작성했고, Finder 빠른 동작에서 실행합니다.

![alt text](example.gif)

## 소개

이미지를 두 장 이상 받아 가로 또는 세로로 한 장으로 합칩니다.

- 가로로 이어 붙이면, 가장 높은 이미지에 맞춰 나머지 이미지의 높이를 키웁니다.
- 세로로 이어 붙이면, 가장 넓은 이미지에 맞춰 나머지 이미지의 너비를 키웁니다.
- 비율은 유지합니다. 이미 기준 크기인 이미지는 다시 확대하지 않습니다.
- 사진의 회전 정보(EXIF)를 반영합니다.
- 결과는 첫 번째 이미지와 같은 폴더에 PNG로 저장됩니다. 파일 이름은 `piconnect-h.png` 또는 `piconnect-v.png`이고, 같은 이름이 있으면 번호를 붙여 저장합니다.
- 저장이 끝나면 Finder에서 결과 파일을 보여 줍니다.

방향은 빠른 동작 메뉴에서 고릅니다. 실행할 때 대화상자는 뜨지 않습니다.

## 빌드

macOS 14 이상과 Swift(Xcode 또는 Command Line Tools)가 필요합니다.
프로젝트 폴더로 이동합니다.

```bash
cd /Users/.../piconnect
swift build -c release
./scripts/install.sh
```

`install.sh`는 릴리스 빌드를 아래 경로에 복사하고 서명합니다.

```text
$HOME/Library/Application Support/QuickTools/piconnect
```

터미널에서 직접 실행할 수도 있습니다.

```bash
piconnect --horizontal photo1.jpg photo2.jpg
piconnect --vertical photo1.jpg photo2.jpg
```

## 빠른 동작 추가

Automator를 열지 않고 스크립트로 추가합니다. `--language`는 빠른 동작 메뉴의 언어입니다.

한국어 메뉴 `가로로 이어붙이기`, `세로로 이어붙이기`:

```bash
./scripts/add-quick-action.sh --language ko
```

영어 메뉴 `Join Horizontally`, `Join Vertically`:

```bash
./scripts/add-quick-action.sh --language en
```

`--language`에 쓸 수 있는 값은 `ko`와 `en`뿐입니다. 다른 언어로 다시 실행하면 이전 언어의 메뉴는 제거되고, 선택한 언어의 메뉴만 남습니다.

각 메뉴는 설치된 `piconnect`를 `--horizontal` 또는 `--vertical`로 실행합니다. 이미지를 고른 뒤 메뉴를 누르면 바로 이어 붙입니다.

### 사용

1. Finder에서 이미지를 두 장 이상 선택합니다.
2. 우클릭 → **빠른 동작**에서 추가된 메뉴를 고릅니다.
3. 같은 폴더에 결과 PNG가 생기고, Finder에서 그 파일이 선택됩니다.

메뉴가 보이지 않으면 Finder를 다시 실행한 뒤, 이미지를 선택하고 우클릭 → **빠른 동작** → **빠른 동작 사용자화**에서 해당 항목을 켜 주세요.
