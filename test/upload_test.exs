defmodule UploadTest do
  use ExUnit.Case

  @path "test/fixtures/test.txt"

  @plug_upload %Plug.Upload{
    path: @path,
    filename: "test.txt",
    content_type: "text/plain"
  }

  test "from_path/1" do
    upload = Upload.from_path(@path)

    assert is_binary(upload.key)
    assert upload.path == @path
    assert upload.filename == "test.txt"
    assert upload.content_type == "text/plain"
  end

  test "from_plug/1" do
    upload = Upload.from_plug(@plug_upload)

    assert is_binary(upload.key)
    assert upload.path == @path
    assert upload.filename == "test.txt"
    assert upload.content_type == "text/plain"
  end
end
