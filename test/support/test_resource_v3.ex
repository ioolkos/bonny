defmodule TestResourceV3 do
  @moduledoc """
  Like TestResourceV2 but observed generations are rejected.
  """

  use Bonny.ControllerV2,
    skip_observed_generations: true

  @impl true
  @spec conn() :: K8s.Conn.t()
  def conn(), do: Bonny.Test.IntegrationHelper.conn()

  @impl Bonny.ControllerV2
  def list_operation() do
    __MODULE__
    |> Bonny.ControllerV2.list_operation()
    |> K8s.Operation.put_label_selector(K8s.Selector.label({"version", "3.1"}))
  end

  @impl true
  @spec customize_crd(Bonny.CRDV2.t()) :: Bonny.CRDV2.t()
  def customize_crd(crd) do
    struct!(
      crd,
      versions: [
        Bonny.CRD.Version.new!(
          name: "v1",
          schema: %{
            openAPIV3Schema: %{
              type: :object,
              properties: %{
                spec: %{
                  type: :object,
                  properties: %{
                    pid: %{type: :string},
                    ref: %{type: :string},
                    rand: %{type: :string}
                  }
                },
                status: %{
                  type: :object,
                  properties: %{
                    rand: %{type: :string}
                  }
                }
              }
            }
          },
          subresources: %{
            status: %{}
          }
        )
      ]
    )
  end

  @impl true
  def apply(resource), do: respond(resource, :applied)

  @impl true
  def delete(resource), do: respond(resource, :deleted)

  @spec add(map()) :: :ok | :error
  def add(resource), do: respond(resource, :created)

  @spec modify(map()) :: :ok | :error
  def modify(resource), do: respond(resource, :modified)

  @spec reconcile(map()) :: :ok | :error
  def reconcile(resource), do: respond(resource, :reconciled)

  defp parse_pid(pid), do: pid |> String.to_charlist() |> :erlang.list_to_pid()
  defp parse_ref(ref), do: ref |> String.to_charlist() |> :erlang.list_to_ref()

  defp respond(resource, action) do
    pid = resource |> get_in(["spec", "pid"]) |> parse_pid()
    ref = resource |> get_in(["spec", "ref"]) |> parse_ref()
    name = resource |> get_in(["metadata", "name"])

    send(pid, {ref, action, name})
    :ok
  end
end
