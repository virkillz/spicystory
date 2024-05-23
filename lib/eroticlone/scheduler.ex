defmodule Eroticlone.Scheduler do
  alias Eroticlone.Content
  use GenServer

  # Eroticlone.Scheduler.start_link(%{})

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{})
  end

  def init(state) do
    # Eroticlone.process_unstarted(60)
    # Schedule work to be performed at some point
    schedule_work()
    {:ok, state}
  end

  def handle_info(:work, state) do
    # spawn(fn -> Eroticlone.process_unstarted(65) end)

    story = Content.get_random_story()
    Eroticlone.generate_female_image_prompt(story)

    # Do the work you desire here
    # Reschedule once more
    schedule_work()
    {:noreply, state}
  end

  defp schedule_work() do
    # In 2 hours
    Process.send_after(self(), :work, 3 * 1000)
  end
end
