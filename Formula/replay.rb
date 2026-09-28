class Replay < Formula
  desc "Reproduce production HTTP traffic from Envoy access logs"
  homepage "https://github.com/reqfleet/replay"
  url "https://github.com/reqfleet/replay/releases/download/v0.2.0/replay-darwin-arm64"
  sha256 "376963aa45c11c0ce4a8ffa544342eba01762be2f5a5914de4b8e9383fbdd962"

  on_macos do
    depends_on arch: :arm64
  end

  on_linux do
    on_intel do
      url "https://github.com/reqfleet/replay/releases/download/v0.2.0/replay-linux-amd64"
      sha256 "cbc4f1b85d144e9f3ed0656fc898d09f4e5afa0eef6310de2f339acb64ba912c"
    end
    on_arm do
      url "https://github.com/reqfleet/replay/releases/download/v0.2.0/replay-linux-arm64"
      sha256 "556f2f5c9c5c0c10dc9fc823eb52d8dd5d4840b0098b8fafbcf1e767f5a70f95"
    end
  end

  def install
    bin.install File.basename(stable.url) => "replay"
  end

  test do
    request = {
      node:          "homebrew",
      connection_id: 1,
      request_id:    "homebrew-test",
      timestamp:     "2026-09-01T00:00:00Z",
      protocol:      "HTTP/1.1",
      method:        "GET",
      authority:     "127.0.0.1:1",
      path:          "/homebrew",
    }
    capture = [
      request.merge(type: "DownstreamStart"),
      request.merge(type: "DownstreamEnd", response_code: 200, response_flags: "DC", duration_ms: 1),
    ]
    (testpath/"capture.ndjson").write(capture.map(&:to_json).join("\n") + "\n")

    system bin/"replay", "combine", "-log", testpath/"capture.ndjson", "-out", testpath/"canonical.ndjson"

    records = (testpath/"canonical.ndjson").readlines.map { |line| JSON.parse(line) }
    assert_equal ["request", "connection_close"], records.map { |record| record.fetch("type") }
    assert_equal "/homebrew", records.first.fetch("path")
    assert_equal 200, records.first.fetch("response_code")
  end
end
