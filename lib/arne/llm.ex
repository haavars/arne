defmodule Arne.Llm do
  def serving do
    repo = {
      :hf,
      "meta-llama/Llama-2-7b-chat-hf",
      auth_token: "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"
    }

    {:ok, model_info} = Bumblebee.load_model(repo, backend: {EXLA.Backend, client: :host})
    {:ok, tokenizer} = Bumblebee.load_tokenizer(repo)
    {:ok, generation_config} = Bumblebee.load_generation_config(repo)
    generation_config = Bumblebee.configure(generation_config, max_new_tokens: 500)

    Bumblebee.Text.generation(model_info, tokenizer, generation_config,
      compile: [batch_size: 1, sequence_length: 1028],
      stream: true,
      defn_options: [compiler: EXLA, lazy_transfers: :always, client: :cuda]
    )
  end
end
