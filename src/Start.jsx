import React from "react";
import { useNavigate } from "react-router-dom";

const Start = () => {
  const navigate = useNavigate();

  const handleStartClick = () => {
    navigate("/register");
  };

  return (
  <div
  style={{
    width: "100vw",
    height: "100vh",
    overflow: "hidden", // <-- prevent scroll
    backgroundImage: "url('/assets/bg.png')",
    backgroundSize: "cover",
    backgroundPosition: "center",
    display: "flex",
    justifyContent: "center",
    alignItems: "center",
  }}


    >
      <button
        onClick={handleStartClick}
        style={{
          width: "490px",            // 80% of viewport width
          height: "125px",
          backgroundImage: "url('/assets/start-button.png')",
          backgroundSize: "cover",
          backgroundPosition: "center",
          backgroundRepeat: "no-repeat",
          border: "none",
          outline: "none",
          cursor: "pointer",
        }}
      />
    </div>
  );
};

export default Start;
