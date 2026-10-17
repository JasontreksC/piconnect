import AppKit
import Foundation

let usage = """
사용법: piconnect --horizontal|--vertical [옵션] 이미지...

  --horizontal, --vertical   이어붙일 방향
  --direction, -d 값         horizontal, vertical, h, v
  --output, -o 경로          저장할 파일. 기본은 첫 이미지와 같은 폴더의 piconnect-h.png / piconnect-v.png
  --sort-name                파일 이름 순으로 정렬. 기본은 받은 순서
  --no-reveal                완료 후 Finder에서 결과를 보여 주지 않음
  --help                     이 도움말

이어붙이는 축의 가장 큰 이미지에 맞춰 나머지를 비율 유지한 채 확대합니다.
"""

struct Options {
    var direction: Direction?
    var output: URL?
    var sortName = false
    var reveal = true
    var help = false
    var paths: [URL] = []
}

@main
struct Piconnect {
    static func main() {
        let code = PiconnectApp().run()
        if code != 0 {
            exit(code)
        }
    }
}

@MainActor
final class PiconnectApp {
    func run() -> Int32 {
        do {
            let options = try parse(CommandLine.arguments)
            if options.help {
                print(usage)
                return 0
            }

            guard let direction = options.direction else {
                throw PiconnectError.usage("방향을 --horizontal 또는 --vertical 로 지정하세요.\n\n\(usage)")
            }

            let urls = try collect(options.paths, sortName: options.sortName)
            let images = try urls.map { try ImageStitcher.load(url: $0) }
            let stitched = try ImageStitcher.stitch(images, direction: direction)
            let output = options.output ?? ImageStitcher.outputURL(near: urls[0], direction: direction)
            try ImageStitcher.savePNG(stitched, to: output)
            print(output.path)
            log("saved \(output.path)")
            if options.reveal {
                NSWorkspace.shared.activateFileViewerSelecting([output])
            }
            return 0
        } catch {
            let message = (error as? LocalizedError)?.errorDescription ?? String(describing: error)
            fputs(message + "\n", stderr)
            log("error: \(message)")
            return 1
        }
    }
}

private func parse(_ argv: [String]) throws -> Options {
    var options = Options()
    var index = 1

    func value(for flag: String) throws -> String {
        index += 1
        guard index < argv.count else {
            throw PiconnectError.usage("\(flag) 뒤에 값이 필요합니다.\n\n\(usage)")
        }
        return argv[index]
    }

    while index < argv.count {
        let argument = argv[index]
        switch argument {
        case "--help", "-help":
            options.help = true
        case "--horizontal":
            options.direction = .horizontal
        case "--vertical":
            options.direction = .vertical
        case "--direction", "-d":
            let raw = try value(for: argument)
            guard let direction = Direction(argument: raw) else {
                throw PiconnectError.usage("방향을 알 수 없습니다: \(raw)\n\n\(usage)")
            }
            options.direction = direction
        case "--output", "-o":
            options.output = URL(fileURLWithPath: (try value(for: argument)).expandingTilde)
        case "--sort-name":
            options.sortName = true
        case "--no-reveal":
            options.reveal = false
        case "--":
            index += 1
            while index < argv.count {
                options.paths.append(URL(fileURLWithPath: argv[index].expandingTilde))
                index += 1
            }
            return options
        case let other where other.hasPrefix("-"):
            throw PiconnectError.usage("알 수 없는 옵션: \(other)\n\n\(usage)")
        default:
            options.paths.append(URL(fileURLWithPath: argument.expandingTilde))
        }
        index += 1
    }
    return options
}

private func collect(_ urls: [URL], sortName: Bool) throws -> [URL] {
    var images: [URL] = []
    var seen = Set<String>()
    let fileManager = FileManager.default

    for url in urls {
        let path = url.standardizedFileURL.resolvingSymlinksInPath()
        let key = path.path
        if seen.contains(key) { continue }
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: path.path, isDirectory: &isDirectory),
              !isDirectory.boolValue,
              ImageStitcher.isImageFile(path)
        else { continue }
        seen.insert(key)
        images.append(path)
    }

    if sortName {
        images.sort {
            $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending
        }
    }

    guard images.count >= 2 else {
        throw PiconnectError.tooFewImages(images.count)
    }
    return images
}

private func log(_ message: String) {
    let url = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library/Logs/piconnect.log")
    let line = "\(ISO8601DateFormatter().string(from: Date())) \(message)\n"
    guard let data = line.data(using: .utf8) else { return }
    if FileManager.default.fileExists(atPath: url.path),
       let handle = try? FileHandle(forWritingTo: url) {
        defer { try? handle.close() }
        _ = try? handle.seekToEnd()
        try? handle.write(contentsOf: data)
    } else {
        try? data.write(to: url)
    }
}

private extension String {
    var expandingTilde: String {
        (self as NSString).expandingTildeInPath
    }
}
