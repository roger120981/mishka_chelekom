defmodule MishkaWeb.Components.Collapse do
  @moduledoc """
  The `<%= @module %>` module implements a mobile navigation component
  that provides a responsive navigation menu optimized for mobile devices in a Phoenix LiveView application.

  ## Features:
  - Highly customizable mobile navigation drawer with smooth animations
  - Support for links, buttons and custom items in the navigation menu
  - Built-in handling of navigation state and menu toggling
  - Responsive breakpoints for showing/hiding based on screen size
  - Customizable styling including colors, spacing and transitions
  - Optional backdrop overlay with configurable opacity
  - Accessibility features like focus management and ARIA attributes
  - Event handlers for menu open/close actions
  - Slots for header, footer and menu items content

  ## Component Structure:
  - Main mobile nav container with drawer sliding animation
  - Optional backdrop overlay when menu is open
  - Header section for branding/close button
  - Body section containing navigation items
  - Footer section for additional content
  - State management for open/closed status

  **Documentation:** https://mishka.tools/chelekom/docs/collapse
  """
  use Phoenix.Component

  @doc """
    The `collapse` component provides a toggle mechanism to show or hide content. It's commonly used
    for creating expandable/collapsible sections in your UI, like accordions or dropdown panels.

    ### Examples
    Basic usage:

        <.collapse id="my-collapse">
          <:trigger>
            <button class="px-4 py-2 bg-gray-100 hover:bg-gray-200 rounded-lg">
              Toggle Content
            </button>
          </:trigger>
          <p class="p-4">
            This content can be toggled on/off.
          </p>
        </.collapse>

    With initial open state and custom duration:

        <.collapse id="settings" open={true} duration={300}>
          <:trigger>
            <div class="flex items-center justify-between w-full">
              <span>Settings</span>
              <.icon name="hero-chevron-down" class="w-5 h-5" />
            </div>
          </:trigger>
          <div class="space-y-4 p-4">
            <h3>User Preferences</h3>
            <p>Configure your settings here...</p>
          </div>
        </.collapse>

    With server events:

        <.collapse
          id="notifications"
          server_events={true}
          target="notifications-component"
        >
          <:trigger>
            <button class="flex items-center gap-2">
              <span>Notifications</span>
              <span class="badge">{@unread_count}</span>
            </button>
          </:trigger>
          <div class="p-4">
            <div :for={notification <- @notifications} class="notification-item">
              <p>{notification.text}</p>
            </div>
          </div>
        </.collapse>
  """

  @doc type: :component
  attr(:id, :string,
    required: true,
    doc: "A unique identifier for the collapse"
  )

  attr(:class, :string, default: nil, doc: "Custom CSS class for additional styling")
  attr(:duration, :integer, default: 200, doc: "Animation duration in milliseconds")
  attr(:keep_mounted, :boolean, default: false, doc: "Keep content mounted after first open")
  attr(:server_events, :boolean, default: false, doc: "Send open/close events to LiveView")
  attr(:target, :string, default: nil, doc: "Target component for server events")
  attr(:open, :boolean, default: false, doc: "Whether the collapse is initially open")

  slot(:trigger, required: true, doc: "The clickable trigger element")
  slot(:inner_block, required: true, doc: "The collapsible content")

  def collapse(assigns) do
    assigns =
      assigns
      |> assign_defaults()
      |> assign(:item_id, "#{assigns.id}-item")

    ~H"""
    <div
      id={@id}
      phx-hook="Collapsible"
      data-multiple="false"
      data-collapsible="true"
      data-duration={@duration}
      data-keep-mounted={@keep_mounted}
      data-server-events={@server_events}
      data-target={@target}
      data-initial-open={if @open, do: @item_id, else: ""}
      class={@class}
    >
      <div class="collapse-item">
        <div
          data-collapsible-trigger={@item_id}
          class="collapse-trigger"
        >
          {render_slot(@trigger)}
        </div>

        <div
          data-collapsible-panel={@item_id}
          class="collapse-panel"
        >
          <div
            data-collapsible-content
            class="transition-[max-height] max-h-0"
            data-duration={@duration}
          >
            <div class="collapse-content">{render_slot(@inner_block)}</div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def handle_event("collapsible_open", %{"item_id" => item_id, "open_ids" => open_ids}, socket) do
    socket = assign(socket, :open_collapse_items, open_ids)
    {:noreply, socket}
  end

  def handle_event("collapsible_close", %{"item_id" => item_id, "open_ids" => open_ids}, socket) do
    socket = assign(socket, :open_collapse_items, open_ids)
    {:noreply, socket}
  end

  defp assign_defaults(assigns) do
    assigns
    |> assign_new(:duration, fn -> 200 end)
    |> assign_new(:keep_mounted, fn -> false end)
    |> assign_new(:server_events, fn -> false end)
    |> assign_new(:target, fn -> nil end)
    |> assign_new(:open, fn -> false end)
  end
end
