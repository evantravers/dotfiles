{ config, pkgs, ... }:
{
  home.packages = with pkgs; [
    unstable.llama-cpp
  ];

  home.sessionVariables = {
    PI_AGENT_DIR = "${config.xdg.configHome}/pi";
    PI_CODING_AGENT_DIR = "${config.xdg.configHome}/pi/agent/";
  };

  xdg.configFile."pi/agent/models.json".text = ''
    {
      "providers": {
        "llama-cpp": {
          "baseUrl": "http://localhost:8080/v1",
          "api": "openai-completions",
          "apiKey": "none",
          "models": [
            {
              "id": "bartowski/Qwen_Qwen3.6-27B-GGUF:Q4_K_M"
            }
          ]
        }
      }
    }
  '';
}
