# radix-up: dynamo-sglang

[radix-up](https://github.com/FrankLeeeee/radix-up) project for Dynamo + SGLang work on the SGLang community GPU cluster.

On each assigned node it clones `livingshade/dynamo` (with `ai-dynamo/dynamo` as `upstream`) into `~/dynamo`, configures git, and starts a background prefetch of the Dynamo SGLang runtime image and test models into `~/hf` (log: `~/prefetch.log`).

```bash
git clone https://github.com/livingshade/radix-up-dynamo.git ~/.config/radix-up/projects/dynamo-sglang
radix-up assign <machine-id> --gpus 1 --duration 4h --project dynamo-sglang
radix-up ssh <machine-id> 'cd ~/dynamo && dynamo-pytest tests/frontend/test_tool_calling_sglang.py -v'
```

Optional settings go in `files/.radix_env` (gitignored, pushed to the node): `GH_TOKEN`, `HF_TOKEN`, `DYNAMO_SGLANG_IMAGE`, `PREFETCH_MODELS`.
