defmodule Upload.Blob do
  @moduledoc """
  An `Ecto.Schema` that represents an uploaded file in the database.
  """

  require Logger

  use Ecto.Schema

  alias Ecto.Changeset
  alias Upload.Key
  alias Upload.Storage

  @type t() :: %__MODULE__{}

  @required_fields [:path, :filename]
  @optional_fields [:content_type]

  schema Upload.Config.get(__MODULE__, :table_name, "blobs") do
    field :key, :string
    field :filename, :string
    field :content_type, :string
    field :byte_size, :integer
    field :checksum, :string
    field :path, :string, virtual: true
    timestamps(updated_at: false)
  end

  @spec from_plug(%{__struct__: Plug.Upload}) :: Changeset.t()
  def from_plug(%{__struct__: Plug.Upload} = upload) do
    changeset(%__MODULE__{}, Map.from_struct(upload))
  end

  @spec from_path(Path.t()) :: Changeset.t()
  def from_path(path) do
    changeset(
      %__MODULE__{},
      %{
        path: path,
        filename: Path.basename(path),
        content_type: MIME.from_path(path)
      }
    )
  end

  @spec changeset(t(), map()) :: Changeset.t()
  def changeset(%__MODULE__{} = upload, attrs \\ %{}) do
    upload
    |> Changeset.cast(attrs, @required_fields ++ @optional_fields)
    |> Changeset.validate_required(@required_fields)
    |> Changeset.prepare_changes(&perform_upload/1)
  end

  @spec perform_upload(Changeset.t()) :: Changeset.t()
  def perform_upload(%Changeset{} = changeset) do
    key = Key.generate()
    path = Changeset.get_change(changeset, :path)

    with {:ok, %{size: byte_size}} <- File.stat(path),
         {:ok, checksum} <- FileStore.Stat.checksum_file(path),
         :ok <- Storage.upload(path, key) do
      changeset
      |> Changeset.put_change(:key, key)
      |> Changeset.put_change(:byte_size, byte_size)
      |> Changeset.put_change(:checksum, checksum)
    else
      {:error, reason} ->
        Changeset.add_error(changeset, :base, "upload failed", reason: reason)
    end
  end
end
