defmodule SpreaderWeb.HomeLive do
  use SpreaderWeb, :live_view
  alias Spreader.Accounts

  @impl true
  def mount(_params, _session, socket) do
    user_count = get_user_count()

    socket =
      socket
      |> assign(:user_count, user_count)
      |> assign(:page_title, "Spreader - Multi-Platform Upload Solution")

    # 매 30초마다 사용자 수 업데이트
    if connected?(socket) do
      :timer.send_interval(30_000, self(), :update_user_count)
    end

    {:ok, socket}
  end

  @impl true
  def handle_info(:update_user_count, socket) do
    {:noreply, assign(socket, :user_count, get_user_count())}
  end

  @impl true
  def handle_event("scroll_to_pricing", _, socket) do
    {:noreply, push_event(socket, "scroll-to", %{id: "pricing-section"})}
  end

  @impl true
  def handle_event("scroll_to_faq", _, socket) do
    {:noreply, push_event(socket, "scroll-to", %{id: "faq-section"})}
  end

  @impl true
  def handle_event("scroll_to_features", _, socket) do
    {:noreply, push_event(socket, "scroll-to", %{id: "features-section"})}
  end

  @impl true
  def handle_event("signup", _, socket) do
    {:noreply, push_navigate(socket, to: ~p"/users/register")}
  end

  @impl true
  def handle_event("login", _, socket) do
    {:noreply, push_navigate(socket, to: ~p"/users/log_in")}
  end

  @impl true
  def handle_event("tour_dashboard", _, socket) do
    {:noreply, push_navigate(socket, to: ~p"/users/register?tour=true")}
  end

  defp get_user_count do
    # 실제 구현에서는 Accounts 모듈을 통해 사용자 수를 가져오도록 수정하세요
    # 현재는 시연을 위해 고정 값이나 랜덤 값을 제공
    start_count = 1500
    # 랜덤하게 증가하는 효과를 위해 ±50 범위 내에서 랜덤 값 추가
    start_count + :rand.uniform(100)
  end
end
