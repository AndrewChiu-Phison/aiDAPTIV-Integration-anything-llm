const { loadSummarizationChain } = require("langchain/chains");
const { PromptTemplate } = require("@langchain/core/prompts");
const { RecursiveCharacterTextSplitter } = require("@langchain/textsplitters");
const Provider = require("../providers/ai-provider");
const { getBaseLLMProviderModel } = require("../../../helpers");
/**
 * @typedef {Object} LCSummarizationConfig
 * @property {string} provider The LLM to use for summarization (inherited)
 * @property {string} model The LLM Model to use for summarization (inherited)
 * @property {AbortController['signal']} controllerSignal Abort controller to stop recursive summarization
 * @property {string} content The text content of the text to summarize
 */

/**
 * Summarize content using LLM LC-Chain call
 * @param {LCSummarizationConfig} The LLM to use for summarization (inherited)
 * @returns {Promise<string>} The summarized content.
 */
async function resolveLLMConfig({ provider, model }) {
  let resolvedProvider = provider ?? process.env.LLM_PROVIDER ?? "openai";
  let resolvedModel =
    model ?? getBaseLLMProviderModel({ provider: resolvedProvider }) ?? null;

  const missingOpenAiKey =
    resolvedProvider === "openai" && !process.env.OPEN_AI_KEY;
  const genericEndpointConfigured =
    !!process.env.GENERIC_OPEN_AI_BASE_PATH &&
    !!process.env.GENERIC_OPEN_AI_API_KEY;

  if (missingOpenAiKey && genericEndpointConfigured) {
    resolvedProvider = "generic-openai";
    resolvedModel =
      model ??
      getBaseLLMProviderModel({ provider: "generic-openai" }) ??
      process.env.GENERIC_OPEN_AI_MODEL_PREF ??
      resolvedModel;
  }

  if (!resolvedModel) {
    throw new Error(
      `No model configured for ${resolvedProvider}. Please review your LLM settings.`
    );
  }

  return { provider: resolvedProvider, model: resolvedModel };
}

async function summarizeContent({
  provider = null,
  model = null,
  controllerSignal,
  content,
}) {
  const { provider: resolvedProvider, model: resolvedModel } =
    await resolveLLMConfig({ provider, model });

  const llm = Provider.LangChainChatModel(resolvedProvider, {
    temperature: 0,
    model: resolvedModel,
  });

  const textSplitter = new RecursiveCharacterTextSplitter({
    separators: ["\n\n", "\n"],
    chunkSize: 10000,
    chunkOverlap: 500,
  });
  const docs = await textSplitter.createDocuments([content]);

  const mapPrompt = `
      Write a detailed summary of the following text for a research purpose:
      "{text}"
      SUMMARY:
      `;

  const mapPromptTemplate = new PromptTemplate({
    template: mapPrompt,
    inputVariables: ["text"],
  });

  // This convenience function creates a document chain prompted to summarize a set of documents.
  const chain = loadSummarizationChain(llm, {
    type: "map_reduce",
    combinePrompt: mapPromptTemplate,
    combineMapPrompt: mapPromptTemplate,
    verbose: process.env.NODE_ENV === "development",
  });

  const res = await chain.call({
    ...(controllerSignal ? { signal: controllerSignal } : {}),
    input_documents: docs,
  });

  return res.text;
}

module.exports = { summarizeContent };
