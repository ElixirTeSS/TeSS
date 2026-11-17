(function () {
  "use strict";

  const DRAFT_KEY = "egi-chat-pending-draft";
  const RESULT_KEY = "egi-chat-last-result";
  const HISTORY_KEY = "egi-chat-history";
  const MAX_HISTORY = 20;

  function initializeEgiChat() {
    const toggleBtn = document.getElementById("egi-chat-toggle");
    const closeBtn = document.getElementById("egi-chat-close");
    const clearBtn = document.getElementById("egi-chat-clear");
    const chatWindow = document.getElementById("egi-chat-window");
    const sendBtn = document.getElementById("egi-chat-send");
    const inputField = document.getElementById("egi-chat-input");
    const messagesContainer = document.getElementById("egi-chat-messages");
    function getUsername() {
      return (
        toggleBtn.getAttribute("data-username") ||
        toggleBtn.dataset.username ||
        "Guest"
      );
    }

    let username = getUsername();

    if (
      !toggleBtn ||
      !closeBtn ||
      !chatWindow ||
      !sendBtn ||
      !inputField ||
      !messagesContainer
    ) {
      return;
    }

    // Avoid duplicate handlers on the same DOM element.
    if (toggleBtn.dataset.egiChatInitialized === "true") {
      return;
    }

    toggleBtn.dataset.egiChatInitialized = "true";
    console.log("EGI Chat: Initialized!");

    let conversationHistory = [];
    let transcript = [];
    let isSending = false;

    // ---------------------------------------------------------
    // Draft persistence
    // ---------------------------------------------------------

    function saveDraft(value) {
      try {
        if (typeof value === "string" && value.trim()) {
          sessionStorage.setItem(DRAFT_KEY, value);
        } else {
          sessionStorage.removeItem(DRAFT_KEY);
        }
      } catch (error) {
        console.warn("EGI Chat: Could not save draft.", error);
      }
    }

    function restoreDraft() {
      try {
        return sessionStorage.getItem(DRAFT_KEY) || "";
      } catch (error) {
        console.warn("EGI Chat: Could not restore draft.", error);
        return "";
      }
    }

    function clearDraft() {
      try {
        sessionStorage.removeItem(DRAFT_KEY);
      } catch (error) {
        console.warn("EGI Chat: Could not clear draft.", error);
      }
    }

    // ---------------------------------------------------------
    // Full transcript persistence
    // ---------------------------------------------------------

    function saveChatState() {
      try {
        sessionStorage.setItem(
          HISTORY_KEY,
          JSON.stringify({
            conversationHistory: conversationHistory,
            transcript: transcript,
            savedAt: Date.now(),
          }),
        );
      } catch (error) {
        console.warn("EGI Chat: Could not save chat history.", error);
      }
    }

    function restoreChatState() {
      try {
        const saved = sessionStorage.getItem(HISTORY_KEY);

        if (!saved) {
          return false;
        }

        const state = JSON.parse(saved);

        if (!state || !Array.isArray(state.transcript)) {
          return false;
        }

        conversationHistory = Array.isArray(state.conversationHistory)
          ? state.conversationHistory
          : [];

        transcript = state.transcript;

        messagesContainer.replaceChildren();

        // Rebuild the transcript using the existing safe renderers.
        transcript.forEach(function (item) {
          if (item.type === "message") {
            renderMessage(item.role, item.text);
          } else if (item.type === "section") {
            renderSection(item.role, item.heading, item.text);
          }
        });

        messagesContainer.scrollTop = messagesContainer.scrollHeight;

        console.log("EGI Chat: Previous conversation restored!");

        return true;
      } catch (error) {
        console.warn("EGI Chat: Could not restore chat history.", error);
        return false;
      }
    }

    // Update the Welcome message in the chatbot interface
    function updateWelcomeMessage() {
      const greeting = `Hello, ${username}! How can I assist you today?`;

      const index = transcript.findIndex(function (item) {
        return (
          item.type === "message" &&
          item.role === "assistant" &&
          /^Hello, .*! How can I assist you today\?$/.test(item.text)
        );
      });

      if (index !== -1) {
        // Update the stored transcript.
        transcript[index].text = greeting;

        // Update the corresponding DOM element.
        const messageElement = messagesContainer.children[index];

        if (messageElement) messageElement.textContent = greeting;

        saveChatState();
      }
    }

    // Keep the latest result key for compatibility with the existing code.
    function saveLastResult(result) {
      try {
        sessionStorage.setItem(RESULT_KEY, JSON.stringify(result));
      } catch (error) {
        console.warn("EGI Chat: Could not save last result.", error);
      }
    }

    function clearSavedChat() {
      try {
        sessionStorage.removeItem(HISTORY_KEY);
        sessionStorage.removeItem(RESULT_KEY);
      } catch (error) {
        console.warn("EGI Chat: Could not clear saved history.", error);
      }
    }

    // ---------------------------------------------------------
    // Restore draft
    // ---------------------------------------------------------

    const savedDraft = restoreDraft();

    if (savedDraft && !inputField.value.trim()) {
      inputField.value = savedDraft;
    }

    inputField.addEventListener("input", function () {
      saveDraft(inputField.value);
    });

    window.addEventListener("pagehide", function () {
      saveDraft(inputField.value);
      saveChatState();
    });

    // ---------------------------------------------------------
    // Open / close chat
    // ---------------------------------------------------------

    toggleBtn.addEventListener("click", function (event) {
      event.preventDefault();
      username = getUsername();

      const isHidden =
        chatWindow.classList.contains("hidden") ||
        chatWindow.hidden ||
        window.getComputedStyle(chatWindow).display === "none";

      if (isHidden) {
        chatWindow.classList.remove("hidden");
        chatWindow.hidden = false;
        chatWindow.setAttribute("aria-hidden", "false");
        toggleBtn.setAttribute("aria-expanded", "true");
        inputField.focus();
      } else {
        chatWindow.classList.add("hidden");
        chatWindow.hidden = true;
        chatWindow.setAttribute("aria-hidden", "true");
        toggleBtn.setAttribute("aria-expanded", "false");
        saveDraft(inputField.value);
      }
    });

    closeBtn.addEventListener("click", function (event) {
      event.preventDefault();

      chatWindow.classList.add("hidden");
      chatWindow.hidden = true;
      chatWindow.setAttribute("aria-hidden", "true");
      toggleBtn.setAttribute("aria-expanded", "false");

      saveDraft(inputField.value);
    });

    // ---------------------------------------------------------
    // Clear transcript and saved history
    // ---------------------------------------------------------

    if (clearBtn) {
      clearBtn.addEventListener("click", function (event) {
        event.preventDefault();

        if (isSending) return;

        conversationHistory = [];
        transcript = [];

        messagesContainer.replaceChildren();

        clearDraft();
        clearSavedChat();

        inputField.value = "";
        inputField.placeholder = "Type a question...";

        appendMessage(
          "assistant",
          `Hello, ${username}! How can I assist you today?`,
        );

        inputField.focus();

        console.log("EGI Chat: Conversation cleared!");
      });
    }

    // ---------------------------------------------------------
    // Send message
    // ---------------------------------------------------------

    async function sendMessage() {
      const text = inputField.value.trim();

      if (!text || isSending) return;

      saveDraft(text);

      appendMessage("user", text);

      conversationHistory.push({
        role: "user",
        content: text,
      });

      conversationHistory = conversationHistory.slice(-MAX_HISTORY);
      saveChatState();

      isSending = true;
      sendBtn.disabled = true;
      inputField.disabled = true;

      const loadingMessage = document.createElement("div");
      loadingMessage.classList.add("chat-msg", "assistant");
      loadingMessage.textContent = "⏳ Thinking...";

      messagesContainer.appendChild(loadingMessage);
      messagesContainer.scrollTop = messagesContainer.scrollHeight;

      const csrfToken = document
        .querySelector('meta[name="csrf-token"]')
        ?.getAttribute("content");

      try {
        const response = await fetch("/api/v1/llm/chat", {
          method: "POST",
          credentials: "same-origin",
          headers: {
            "Content-Type": "application/json",
            Accept: "application/json",
            ...(csrfToken ? { "X-CSRF-Token": csrfToken } : {}),
          },
          body: JSON.stringify({
            messages: [
              {
                role: "user",
                content: text,
              },
            ],
          }),
        });

        if (!response.ok) {
          const errorText = await response.text();

          throw new Error(
            `Request failed with status ${response.status}` +
              (errorText ? `: ${errorText}` : ""),
          );
        }

        const data = await response.json();

        const tess = data?.tess || {};

        const rawAnswer =
          typeof data?.llm?.answer === "string"
            ? data.llm.answer
            : data?.llm?.answer?.choices?.[0]?.message?.content ||
              data?.llm?.answer?.choices?.[0]?.text ||
              data?.llm?.answer?.choice?.[0]?.message?.content ||
              data?.llm?.answer?.choice?.[0]?.text ||
              data?.llm?.choice?.[0]?.message?.content ||
              data?.llm?.choice?.[0]?.text ||
              "No EGI LLM response available!";

        loadingMessage.remove();

        let llm = String(rawAnswer);
        const llmMarker = "[LLM]";
        const llmIndex = llm.lastIndexOf(llmMarker);

        if (llmIndex !== -1) {
          llm = llm.slice(llmIndex + llmMarker.length).trim();
        }

        // Display and record TeSS results.
        const tessText = formatTess(tess);
        appendSection("tess", "[TeSS]", tessText);

        // Display and record the LLM answer.
        appendSection("llm", "[LLM]", llm);

        // Store the latest result as well as the full transcript.
        saveLastResult({
          tess: tess,
          llm: llm,
          savedAt: Date.now(),
        });

        appendMessage(
          "assistant",
          "⚠️WARNING: AI can make mistakes. Check important info.",
        );

        conversationHistory.push({
          role: "assistant",
          content: llm,
        });

        conversationHistory = conversationHistory.slice(-MAX_HISTORY);

        // Save the completed conversation.
        saveChatState();

        inputField.value = "";
        clearDraft();
      } catch (error) {
        console.error("EGI Chat Error:", error);

        loadingMessage.remove();

        appendMessage(
          "assistant",
          `**Response failed**: ${error.message}. 
	   Your question has been preserved; Please try again.`,
        );

        const lastMessage = conversationHistory[conversationHistory.length - 1];

        if (lastMessage && lastMessage.role === "user") {
          conversationHistory.pop();
        }

        inputField.value = text;
        saveDraft(text);
        saveChatState();
      } finally {
        isSending = false;
        sendBtn.disabled = false;
        inputField.disabled = false;
        inputField.focus();
      }
    }

    // ---------------------------------------------------------
    // Message rendering
    // ---------------------------------------------------------

    function renderMessage(role, text) {
      const msgDiv = document.createElement("div");

      msgDiv.classList.add("chat-msg", role);
      msgDiv.textContent = String(text);

      messagesContainer.appendChild(msgDiv);

      return msgDiv;
    }

    function appendMessage(role, text) {
      const messageText = String(text);

      transcript.push({
        type: "message",
        role: role,
        text: messageText,
      });

      const element = renderMessage(role, messageText);

      messagesContainer.scrollTop = messagesContainer.scrollHeight;
      saveChatState();

      return element;
    }

    // ---------------------------------------------------------
    // HTML safety helpers
    // ---------------------------------------------------------

    function escapeHtml(value) {
      return String(value).replace(/[&<>"']/g, function (char) {
        return {
          "&": "&amp;",
          "<": "&lt;",
          ">": "&gt;",
          '"': "&quot;",
          "'": "&#39;",
        }[char];
      });
    }

    function safeHttpUrl(value) {
      try {
        const url = new URL(String(value), window.location.origin);

        if (url.protocol === "http:" || url.protocol === "https:") {
          return url.href;
        }
      } catch (_error) {
        // Ignore invalid URLs.
      }

      return "";
    }

    // ---------------------------------------------------------
    // TeSS formatting
    // ---------------------------------------------------------

    function formatTess(tess = {}) {
      tess = tess || {};

      const sections = [
        ["Events", tess.events],
        ["Materials", tess.materials],
        ["Trainers", tess.trainers],
        ["Content providers", tess.content_providers],
      ];

      return sections
        .map(([label, items]) => {
          if (!Array.isArray(items) || items.length === 0) {
            return `<p><strong>${escapeHtml(label)}:</strong> None found</p>`;
          }

          const formattedItems = items
            .map((item) => {
              const title = item?.title || item?.name || "Untitled";
              const description = item?.description || "";
              const url = safeHttpUrl(item?.url || "");

              let html = `<li><strong>${escapeHtml(title)}:</strong>`;

              if (description) {
                html += ` ${escapeHtml(description)}`;
              }

              if (url) {
                html +=
                  `<br><a href="${escapeHtml(url)}" ` +
                  `target="_blank" rel="noopener noreferrer">` +
                  `${escapeHtml(url)}</a>`;
              }

              html += "</li>";

              return html;
            })
            .join("");

          return (
            `<p><strong>${escapeHtml(label)}:</strong></p>` +
            `<ul>${formattedItems}</ul>`
          );
        })
        .join("");
    }

    // ---------------------------------------------------------
    // Clipboard helper
    // ---------------------------------------------------------

    async function copyToClipboard(text) {
      try {
        if (navigator.clipboard && window.isSecureContext) {
          await navigator.clipboard.writeText(text);
          return true;
        }

        // Fallback for older browsers.
        const textarea = document.createElement("textarea");
        textarea.value = text;
        textarea.style.position = "fixed";
        textarea.style.left = "-9999px";

        document.body.appendChild(textarea);
        textarea.select();

        const copied = document.execCommand("copy");
        textarea.remove();
        return copied;
      } catch (error) {
        console.error("EGI Chat: Clipboard error.", error);
        return false;
      }
    }

    // ---------------------------------------------------------
    // Section rendering
    // ---------------------------------------------------------

    function renderSection(role, heading, text) {
      const section = document.createElement("div");

      section.classList.add("chat-section", `chat-section-${role}`);

      const title = document.createElement("div");
      title.classList.add("chat-section-title");
      title.textContent = heading;

      const content = document.createElement("div");
      content.classList.add("chat-section-content");

      const purifier = window.DOMPurify;

      if (role === "llm") {
        let html = null;

        if (window.marked && purifier) {
          html = window.marked.parse(String(text));
        } else if (window.markdownit && purifier) {
          const md = window.markdownit({
            html: false,
            linkify: true,
            breaks: true,
          });

          html = md.render(String(text));
        }

        if (html !== null && purifier) {
          content.innerHTML = purifier.sanitize(html);
          content.classList.add("markdown-body");
        } else {
          content.textContent = String(text);
        }
      } else if (role === "tess") {
        if (purifier) {
          content.innerHTML = purifier.sanitize(String(text), {
            ALLOWED_TAGS: ["p", "ul", "li", "strong", "a", "br"],
            ALLOWED_ATTR: ["href", "target", "rel"],
          });
        } else {
          // Conservative fallback if DOMPurify is unavailable.
          content.textContent = String(text).replace(/<[^>]*>/g, " ");
        }
      } else {
        content.textContent = String(text);
      }

      section.appendChild(title);
      section.appendChild(content);

      // Add Copy button for TeSS and LLM responses.
      if (role) {
        const copyBtn = document.createElement("button");

        copyBtn.type = "button";
        copyBtn.classList.add("chat-copy-btn");
        copyBtn.textContent = "📋 Copy response";

        copyBtn.addEventListener("click", async function () {
          const copied = await copyToClipboard(String(text));

          if (copied) {
            copyBtn.textContent = "✓ Copied!";
            copyBtn.classList.add("copied");
          } else {
            copyBtn.textContent = "❌ Copy failed";
          }

          setTimeout(function () {
            copyBtn.textContent = "📋 Copy response";
            copyBtn.classList.remove("copied");
          }, 2000);
        });

        section.appendChild(copyBtn);
      }

      messagesContainer.appendChild(section);

      return section;
    }

    function appendSection(role, heading, text) {
      const sectionText = String(text);

      transcript.push({
        type: "section",
        role: role,
        heading: heading,
        text: sectionText,
      });

      const section = renderSection(role, heading, sectionText);

      messagesContainer.scrollTop = messagesContainer.scrollHeight;
      saveChatState();

      return section;
    }

    // ---------------------------------------------------------
    // Send controls
    // ---------------------------------------------------------

    sendBtn.addEventListener("click", function (event) {
      event.preventDefault();
      sendMessage();
    });

    inputField.addEventListener("keydown", function (event) {
      if (event.key === "Enter" && !event.shiftKey) {
        event.preventDefault();
        sendMessage();
      }
    });

    // ---------------------------------------------------------
    // Restore previous transcript on page load/navigation
    // ---------------------------------------------------------

    const restored = restoreChatState();

    if (!restored) {
      appendMessage(
        "assistant",
        `Hello, ${username}! How can I assist you today?`,
      );
    } else {
      updateWelcomeMessage();
    }
  }

  document.addEventListener("DOMContentLoaded", initializeEgiChat);
  document.addEventListener("turbolinks:load", initializeEgiChat);
  document.addEventListener("turbo:load", initializeEgiChat);
})();

