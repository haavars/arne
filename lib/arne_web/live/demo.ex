defmodule ArneWeb.Demo do
  use ArneWeb, :live_view

  alias Phoenix.LiveView.AsyncResult

  def render(assigns) do
    ~H"""
      <div class="flex flex-col items-center w-full">
        <h1 class="text-slate-900 font-extrabold text-3xl tracking-tight text-center">
          Llama2
        </h1>
        <p class="mt-6 text-lg text-slate-600 text-center max-w-4xl mx-auto">
          Powered by <a href="https://github.com/elixir-nx/bumblebee" class="font-mono font-medium text-sky-500">Bumblebee</a>,
          an Nx/Axon library for pre-trained and transformer models with <a href="https://huggingface.co">🤗</a> integration.
        </p>
        <div class="mt-6 w-full mx-auto">
          <form phx-change="validate" phx-submit="generate" class="space-y-5 max-w-4xl mx-auto">
            <div>
              <label for="prompt" class="block text-sm font-medium leading-6 text-gray-900">Prompt</label>
              <div class="mt-2">
                <textarea
                  id="prompt"
                  name="prompt"
                  rows="4"
                  class="block w-full rounded-md border-0 p-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6"
                ><%= @prompt %></textarea>
              </div>
            </div>
            <button disabled={!!@output.loading} type="submit" class="rounded-md bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600">
              Generate
              <.spinner :if={@output.loading} />
            </button>
            <p id="output" phx-update="stream" class="text-md py-5">
              <span :for={{id, segment} <- @streams.output} id={id}><%= segment.content %></span>
            </p>
          </form>
        </div>
      </div>
    """
  end

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> stream(:output, [])
     |> assign(
       prompt: nil,
       output: AsyncResult.ok(AsyncResult.loading(), [])
     )}
  end

  def handle_event("validate", %{"prompt" => prompt}, socket) do
    {:noreply, assign(socket, prompt: prompt)}
  end

  def handle_event("generate", %{"prompt" => prompt}, socket) do
    parent = self()

    {:noreply,
     socket
     |> assign(prompt: prompt, output: AsyncResult.loading())
     |> stream(:output, [], reset: true)
     |> cancel_async(:output)
     |> start_async(:output, fn ->
       for {segment, index} <-
             Stream.with_index(Nx.Serving.batched_run(ChatServing, prompt)) do
         send(parent, {:output, {segment, index}})
       end
     end)}
  end

  def handle_info({:output, {segment, index}}, socket) do
    {:noreply, stream(socket, :output, [%{id: "s-#{index}", content: segment}])}
  end

  def handle_async(:output, {:ok, _}, socket) do
    {:noreply, assign(socket, :output, AsyncResult.ok(socket.assigns.output, []))}
  end

  defp spinner(assigns) do
    ~H"""
    <svg phx-no-format class="inline ml-1 w-4 h-4 text-gray-200 animate-spin fill-blue-600" viewBox="0 0 100 101" fill="none" xmlns="http://www.w3.org/2000/svg">
      <path d="M100 50.5908C100 78.2051 77.6142 100.591 50 100.591C22.3858 100.591 0 78.2051 0 50.5908C0 22.9766 22.3858 0.59082 50 0.59082C77.6142 0.59082 100 22.9766 100 50.5908ZM9.08144 50.5908C9.08144 73.1895 27.4013 91.5094 50 91.5094C72.5987 91.5094 90.9186 73.1895 90.9186 50.5908C90.9186 27.9921 72.5987 9.67226 50 9.67226C27.4013 9.67226 9.08144 27.9921 9.08144 50.5908Z" fill="currentColor" />
      <path d="M93.9676 39.0409C96.393 38.4038 97.8624 35.9116 97.0079 33.5539C95.2932 28.8227 92.871 24.3692 89.8167 20.348C85.8452 15.1192 80.8826 10.7238 75.2124 7.41289C69.5422 4.10194 63.2754 1.94025 56.7698 1.05124C51.7666 0.367541 46.6976 0.446843 41.7345 1.27873C39.2613 1.69328 37.813 4.19778 38.4501 6.62326C39.0873 9.04874 41.5694 10.4717 44.0505 10.1071C47.8511 9.54855 51.7191 9.52689 55.5402 10.0491C60.8642 10.7766 65.9928 12.5457 70.6331 15.2552C75.2735 17.9648 79.3347 21.5619 82.5849 25.841C84.9175 28.9121 86.7997 32.2913 88.1811 35.8758C89.083 38.2158 91.5421 39.6781 93.9676 39.0409Z" fill="currentFill" />
    </svg>
    """
  end
end
