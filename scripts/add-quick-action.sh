#!/bin/zsh
# Finder 빠른 동작을 스크립트로 추가한다. 대화상자는 만들지 않는다.
# --language ko  메뉴: 가로로 이어붙이기, 세로로 이어붙이기
# --language en  메뉴: Join Horizontally, Join Vertically
set -euo pipefail

usage() {
  cat <<'EOF'
사용법: ./scripts/add-quick-action.sh --language ko|en

  --language ko    빠른 동작 메뉴를 한국어로 추가
                   가로로 이어붙이기, 세로로 이어붙이기
  --language en    빠른 동작 메뉴를 영어로 추가
                   Join Horizontally, Join Vertically

다른 언어로 다시 실행하면 이전 언어의 메뉴는 제거됩니다.
먼저 ./scripts/install.sh 로 프로그램을 설치하세요.
EOF
}

language=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --language|--lang)
      [[ $# -ge 2 ]] || { echo "--language 뒤에 ko 또는 en 이 필요합니다." >&2; exit 1; }
      language="$2"
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "알 수 없는 옵션: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

[[ -n "$language" ]] || { usage >&2; exit 1; }

case "$language" in
  ko) lang=ko ;;
  en) lang=en ;;
  *)
    echo "언어를 알 수 없습니다: $language. ko 또는 en 을 사용하세요." >&2
    exit 1
    ;;
esac

bin="$HOME/Library/Application Support/QuickTools/piconnect"
[[ -x "$bin" ]] || {
  echo "실행 파일이 없습니다. 먼저 ./scripts/install.sh 를 실행하세요." >&2
  exit 1
}

export PICONNECT_BIN="$bin"
export PICONNECT_LANG="$lang"

python3 - <<'PY'
import os
import plistlib
import shutil
import subprocess
import uuid
from pathlib import Path

lang = os.environ["PICONNECT_LANG"]
binary = os.environ["PICONNECT_BIN"]
services = Path.home() / "Library" / "Services"

menus = {
    "ko": (
        ("가로로 이어붙이기", "--horizontal"),
        ("세로로 이어붙이기", "--vertical"),
    ),
    "en": (
        ("Join Horizontally", "--horizontal"),
        ("Join Vertically", "--vertical"),
    ),
}

def service_key(name: str) -> str:
    return f"(null) - {name} - runWorkflowAsService"

def workflow(name: str, flag: str) -> dict:
    command = f'"{binary}" {flag} "$@"'
    action_id = str(uuid.uuid5(uuid.NAMESPACE_URL, f"piconnect:{name}"))
    return {
        "AMApplicationBuild": "534",
        "AMApplicationVersion": "2.10",
        "AMDocumentVersion": "2",
        "actions": [
            {
                "action": {
                    "AMAccepts": {
                        "Container": "List",
                        "Optional": True,
                        "Types": ["com.apple.cocoa.path"],
                    },
                    "AMActionVersion": "2.0.3",
                    "AMApplication": ["Automator"],
                    "AMParameterProperties": {
                        "COMMAND_STRING": {},
                        "CheckedForUserDefaultShell": {},
                        "inputMethod": {},
                        "shell": {},
                        "source": {},
                    },
                    "AMProvides": {
                        "Container": "List",
                        "Types": ["com.apple.cocoa.string"],
                    },
                    "ActionBundlePath": "/System/Library/Automator/Run Shell Script.action",
                    "ActionName": "Run Shell Script",
                    "ActionParameters": {
                        "COMMAND_STRING": command,
                        "CheckedForUserDefaultShell": True,
                        "inputMethod": 1,
                        "shell": "/bin/zsh",
                        "source": "",
                    },
                    "BundleIdentifier": "com.apple.RunShellScript",
                    "CFBundleVersion": "2.0.3",
                    "CanShowSelectedItemsWhenRun": False,
                    "CanShowWhenRun": True,
                    "Category": ["AMCategoryUtilities"],
                    "Class Name": "RunShellScriptAction",
                    "InputUUID": action_id,
                    "Keywords": ["Shell", "Script", "Command", "Run", "Unix"],
                    "OutputUUID": str(uuid.uuid5(uuid.NAMESPACE_URL, f"piconnect-out:{name}")),
                    "UUID": str(uuid.uuid5(uuid.NAMESPACE_URL, f"piconnect-action:{name}")),
                    "UnlocalizedApplications": ["Automator"],
                    "arguments": {
                        "0": {"default value": 0, "name": "inputMethod", "required": "0", "type": "0", "uuid": "0"},
                        "1": {"default value": False, "name": "CheckedForUserDefaultShell", "required": "0", "type": "0", "uuid": "1"},
                        "2": {"default value": "", "name": "source", "required": "0", "type": "0", "uuid": "2"},
                        "3": {"default value": "", "name": "COMMAND_STRING", "required": "0", "type": "0", "uuid": "3"},
                        "4": {"default value": "/bin/sh", "name": "shell", "required": "0", "type": "0", "uuid": "4"},
                    },
                    "conversionLabel": 0,
                    "isViewVisible": 1,
                    "location": "310.000000:305.000000",
                    "nibPath": "/System/Library/Automator/Run Shell Script.action/Contents/Resources/Base.lproj/main.nib",
                },
                "isViewVisible": 1,
            }
        ],
        "connectors": {},
        "workflowMetaData": {
            "applicationBundleID": "com.apple.finder",
            "applicationBundleIDsByPath": {
                "/System/Library/CoreServices/Finder.app": "com.apple.finder",
            },
            "applicationPath": "/System/Library/CoreServices/Finder.app",
            "applicationPaths": ["/System/Library/CoreServices/Finder.app"],
            "inputTypeIdentifier": "com.apple.Automator.fileSystemObject.image",
            "outputTypeIdentifier": "com.apple.Automator.nothing",
            "presentationMode": 15,
            "processesInput": False,
            "serviceApplicationBundleID": "com.apple.finder",
            "serviceApplicationPath": "/System/Library/CoreServices/Finder.app",
            "serviceInputTypeIdentifier": "com.apple.Automator.fileSystemObject.image",
            "serviceOutputTypeIdentifier": "com.apple.Automator.nothing",
            "serviceProcessesInput": False,
            "systemImageName": "NSActionTemplate",
            "useAutomaticInputType": False,
            "workflowTypeIdentifier": "com.apple.Automator.servicesMenu",
        },
    }

def info_plist(name: str) -> dict:
    return {
        "NSServices": [
            {
                "NSBackgroundColorName": "background",
                "NSIconName": "NSActionTemplate",
                "NSMenuItem": {"default": name},
                "NSMessage": "runWorkflowAsService",
                "NSRequiredContext": {"NSApplicationIdentifier": "com.apple.finder"},
                "NSSendFileTypes": ["public.image"],
            }
        ]
    }

def write_plist(path: Path, data: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("wb") as handle:
        plistlib.dump(data, handle, fmt=plistlib.FMT_XML)

services.mkdir(parents=True, exist_ok=True)
owned = [name for items in menus.values() for name, _ in items]
for name in owned:
    folder = services / f"{name}.workflow"
    if folder.exists():
        shutil.rmtree(folder)

for name, flag in menus[lang]:
    root = services / f"{name}.workflow" / "Contents"
    write_plist(root / "Info.plist", info_plist(name))
    write_plist(root / "document.wflow", workflow(name, flag))
    print(root.parent)

raw = subprocess.check_output(["defaults", "export", "pbs", "-"])
preferences = plistlib.loads(raw)
status = preferences.get("NSServicesStatus", {})
entry = {
    "presentation_modes": {
        "ContextMenu": True,
        "FinderPreview": True,
        "ServicesMenu": True,
        "TouchBar": False,
    }
}
for name in owned:
    status.pop(service_key(name), None)
for name, _ in menus[lang]:
    status[service_key(name)] = entry
preferences["NSServicesStatus"] = status
subprocess.run(
    ["defaults", "import", "pbs", "-"],
    input=plistlib.dumps(preferences, fmt=plistlib.FMT_XML),
    check=True,
)
PY

/System/Library/CoreServices/pbs -flush >/dev/null 2>&1 || true

if [[ "$lang" == "ko" ]]; then
  echo "빠른 동작을 추가했습니다."
  echo "  가로로 이어붙이기"
  echo "  세로로 이어붙이기"
else
  echo "Added Quick Actions."
  echo "  Join Horizontally"
  echo "  Join Vertically"
fi
