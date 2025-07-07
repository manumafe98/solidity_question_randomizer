import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import "./index.css";
import { QuestionRandomizer } from "./QuestionRandomizer.tsx";

createRoot(document.getElementById("root")!).render(
  <StrictMode>
    <QuestionRandomizer />
  </StrictMode>
);
