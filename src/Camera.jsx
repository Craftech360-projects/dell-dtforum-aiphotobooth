import React, { useEffect, useRef, useState } from "react";
import { useNavigate } from "react-router-dom";
import styled from "styled-components";
import female from "/assets/female.png";
import male from "/assets/male.png";
import captureImageIcon from "/assets/capture.png"; // Import the PNG image
import bg2 from "/bg2.png"; // or .png
import inputbg from "/assets/inputbg.png";
import submitbg from "/assets/submit.png";
import captureBg from "/assets/capture.png";


import two from "/assets/two.png";
import m1 from "/Male 01.jpg"; // Import the PNG image
import m2 from "/Male 02.jpg"; // Import the PNG image
import m3 from "/Male 03.jpg"; // Import the PNG image
import m4 from "/Male 04.jpg"; // Import the PNG image

import f1 from "/Female 01.jpg"; // Import the PNG image
import f2 from "/Female 02.jpg"; // Import the PNG image
import f3 from "/Female 03.jpg"; // Import the PNG image
import f4 from "/Female 04.jpg"; // Import the PNG image

const imgStyle = {
  width: '572px',
  height: ' 874px',
  objectFit: "cover",
  borderRadius: "15px",
  border: "3px solid #fff",
  cursor: "pointer",
  transition: "all 0.3s ease",
  position: "absolute",
  boxShadow: "0 10px 30px rgba(0,0,0,0.3)",
};

const CaptureButton = styled.button`
  background-image: url(${captureImageIcon});
  background-repeat: no-repeat;
  background-size: contain;
  background-color: transparent;
  border: none;
  width: 270px; /* Adjust width and height according to your image dimensions */
  height: 100px;
  cursor: pointer;
  text-indent: -9999px; /* Hide text visually but keep it for accessibility */
  position: relative;
  margin-top: 90px;
`;
function Camer() {
  const maleImages = ["male1", "male1"];
  const femaleImages = ["female1", "female1"];
  const videoRef = useRef(null);
  const canvasRef = useRef(null);
  const [isCameraOn, setIsCameraOn] = useState(false);
  const navigate = useNavigate();
  const [flash, setFlash] = useState(false);
  const [gender, setGender] = useState(null);
  const [isGender, setIsGender] = useState("");
  const [isStarted, setIsStarted] = useState(true);
  const [isGenderShow, setIsGenderShow] = useState(false);
  const [isOptions, setIsOptions] = useState(false);
  const [isImg, setIsImg] = useState(false);
  const [userDetails, setUserDetails] = useState({ name: "", email: "" });
  const images = {
    male: [m1, m2, m3, m4],
    female: [f1, f2, f3, f4],
  };

  const [currentIndex, setCurrentIndex] = useState(0);


  const getRandomImage = (images) => {
    return images[Math.floor(Math.random() * images.length)];
  };

  const handleArrowClick = (direction) => {
    const length = images[isGender].length;
    setCurrentIndex((prevIndex) =>
      direction === "left"
        ? (prevIndex - 1 + length) % length
        : (prevIndex + 1) % length
    );
  };

  const handleImageClick = () => {
    // Get the actual imported image (e.g., m1, f2) instead of a string
    const selectedImageFile = images[isGender][currentIndex];
  
    // Pass it in the navigation state
    setIsImg(selectedImageFile);
    setIsCameraOn(true);
    setIsGender("");
  };


  const getTransformStyle = (index) => {
    const offset = index - currentIndex;
    const totalImages = images[isGender].length;

    // Calculate circular positions - show 3 images at once
    let adjustedOffset = offset;

    // Handle wrap-around for circular display
    if (offset > totalImages / 2) {
      adjustedOffset = offset - totalImages;
    } else if (offset < -totalImages / 2) {
      adjustedOffset = offset + totalImages;
    }

    // Only show 3 images: center, left, and right
    if (Math.abs(adjustedOffset) > 1) {
      return {
        ...imgStyle,
        opacity: 0,
        pointerEvents: "none",
        transform: "scale(0)",
        zIndex: -1,
      };
    }

    // Position values - INCREASED baseX to prevent overlap
    const baseX = 350; // Increased from 200 to 350 to prevent cutting
    const baseScale = 0.65; // Reduced scale slightly to make side images smaller
    const centerScale = 1; // Scale for center image

    let transform = "";
    let zIndex = 1;
    let filter = "brightness(0.6) blur(2px)";
    let opacity = 0.8;

    if (adjustedOffset === 0) {
      // Center card - main focus
      transform = "translateX(0px) scale(1)";
      zIndex = 10;
      filter = "brightness(1) drop-shadow(0 0 20px #FFD700)";
      opacity = 1;
    } else if (adjustedOffset === -1) {
      // Left side card - moved further left and rotated more
      transform = `translateX(-${baseX}px) scale(${baseScale}) rotateY(25deg)`;
      zIndex = 5;
      filter = "brightness(0.6) blur(2px)";
      opacity = 0.8;
    } else if (adjustedOffset === 1) {
      // Right side card - moved further right and rotated more
      transform = `translateX(${baseX}px) scale(${baseScale}) rotateY(-25deg)`;
      zIndex = 5;
      filter = "brightness(0.6) blur(2px)";
      opacity = 0.8;
    }

    return {
      ...imgStyle,
      transform,
      zIndex,
      opacity,
      filter,
      pointerEvents: adjustedOffset === 0 ? "auto" : "none",
      transition: "all 0.5s cubic-bezier(0.25, 0.46, 0.45, 0.94)",
    };
  };

  // Also update the container style to accommodate the wider spacing
  const carouselContainerStyle = {
    position: "relative",
    width: "100%", // Increased from 1000px to accommodate wider spacing
    height: "900px",
    transformStyle: "preserve-3d",
    display: "flex",
    alignItems: "center",
    justifyContent: "center",
    margin: "0 auto", // Center the carousel
    overflow: "hidden", // Hide any overflow to prevent visual artifacts
  };

  const startProcess = (value) => {
    setIsStarted(false);
    setIsGenderShow(false);
    setIsGender(value);
    setGender(value);
  };

  useEffect(() => {
    if (isCameraOn) {
      navigator.mediaDevices
        .getUserMedia({ video: true })
        .then((stream) => {
          videoRef.current.srcObject = stream;
        })
        .catch((err) => {
          console.error("error:", err);
          setIsCameraOn(false);
        });
    } else {
      if (videoRef.current && videoRef.current.srcObject) {
        let tracks = videoRef.current.srcObject.getTracks();
        tracks.forEach((track) => track.stop());
      }
    }

    return () => {
      if (videoRef.current && videoRef.current.srcObject) {
        let tracks = videoRef.current.srcObject.getTracks();
        tracks.forEach((track) => track.stop());
      }
    };
  }, [isCameraOn]);

  const captureImage = () => {
    setTimeout(() => {
      const canvas = canvasRef.current;
      const context = canvas.getContext("2d");
      const video = videoRef.current;
      canvas.width = video.videoWidth;
      canvas.height = video.videoHeight;
      context.drawImage(video, 0, 0, video.videoWidth, video.videoHeight);
      canvas.toBlob((blob) => {
        // Add animation before navigation
        const section = document.querySelector("section");
        if (section) {
          section.classList.add("animate__animated", "animate__bounceOut");
          setTimeout(() => {
            navigate("/swap", {
              state: { sourceImage: blob, isImg, userDetails },
            });
          }, 1000); // Adjust timing as needed
        }
      }, "image/jpeg");
    }, 500);
  };

  const handleChange = (e) => {
    const { name, value } = e.target;
    setUserDetails((prevDetails) => ({
      ...prevDetails,
      [name]: value,
    }));
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    setIsGenderShow(true);
    setIsStarted(false);
    console.log(userDetails, "userDetails");
  };
  
  return (
    <section
      style={{
        textAlign: "center",
        width: "100%", // Changed from 100vw
        height: "100vh",
        backgroundImage: `url(${bg2})`,
        backgroundSize: "cover",
        backgroundPosition: "center",
        backgroundRepeat: "no-repeat",
        overflow: "hidden", // Prevents any overflow
        margin: 0,
        padding: 0,
        boxSizing: 'border-box'
      }}
    >
      {/* Start button code  */}
      {isStarted && (

        <>
          <style>
            {`
        input::placeholder {
          color: #9A9A9A; /* Placeholder text color */
          font-weight: bold;
        }

        input {
          outline: none;
        }

        button:hover {
          background-color: #2A3AB5; /* Hover background color */
          color: #E6E6E6; /* Hover text color */
        }
          input::placeholder {
        color: #000;
        font-weight: bold;
      }
      `}
          </style>
          <form
            onSubmit={handleSubmit}
            style={{
              display: "flex",
              flexDirection: "column",
              gap: "50px",
              width: "100%",
              height: "100%",
              borderRadius: "10px",
              alignItems: "center",
              justifyContent: "center",
            }}
          >
            <input
              type="text"
              name="name"
              placeholder="Enter your name"
              value={userDetails.name}
              onChange={handleChange}
              style={{
                padding: "42px",
                fontSize: "34px",
                border: "none",
                textAlign: "left",
                color: "#001965",
                fontWeight: "bold",
                width: "55%",
                textTransform: "capitalize",
                backgroundImage: `url(${inputbg})`,
                backgroundSize: "cover",
                backgroundPosition: "center",
                backgroundRepeat: "no-repeat",
              }}
              required
            />

            <input
              type="email"
              name="email"
              placeholder="Enter your email"
              value={userDetails.email}
              onChange={handleChange}
              style={{
                padding: "42px",
                fontSize: "34px",
                border: "none",
                textAlign: "left",
                color: "#001965",
                fontWeight: "bold",
                width: "55%",
                backgroundImage: `url(${inputbg})`,
                backgroundSize: "cover",
                backgroundPosition: "center",
                backgroundRepeat: "no-repeat",
              }}
              required
            />
            <button
              type="submit"
              style={{
                width: "480px",
                height: "95px",
                cursor: "pointer",
                fontSize: "40px",
                color: "#fff",
                transition: "background-color 0.3s ease, color 0.3s ease",
                position: "absolute",
                top: "65%",
                backgroundImage: `url(${submitbg})`,
                backgroundSize: "cover",
                backgroundPosition: "center",
                backgroundRepeat: "no-repeat",
                backgroundColor: "transparent",
                border: "none",
              }}
            >
            </button>


          </form>
        </>
      )}

      {isGenderShow && (
        <div
          style={{
            textAlign: "center",
            width: "100%",
            height: "100%",
            display: "flex",
            flexDirection: "column",
            justifyContent: "center",
            alignItems: "center",
            backgroundRepeat: "no-repeat",
          }}
        >
          {/* NEW heading */}
          <div
            style={{
              fontSize: "64px",     // Big font
              color: "#7A4BFF",     // Purple color
              fontWeight: "bold",
              letterSpacing: "2px",
              marginBottom: "20px", // Space below this heading
            }}
          >
            Select your gender
          </div>

          {/* Existing subheading */}
          <div
            style={{
              fontSize: "32px",
              color: "#fff",
              letterSpacing: "2px",
            }}
          >
            Select Gender
          </div>

          <div
            style={{
              width: "100%",
              height: "auto",
              display: "flex",
              flexDirection: "row",
              justifyContent: "center",
              gap: "20px",
              marginTop: "30px",
            }}
          >
            <button
              style={{
                borderRadius: "10px",
                backgroundImage: `url(${male})`,
                backgroundSize: "cover",
                backgroundPosition: "center",
                backgroundRepeat: "no-repeat",
                width: "366px",
                height: "438px",
                border: "none",
                cursor: "pointer",
                backgroundColor: "transparent",
                transition: "border 0.3s ease",
                boxSizing: "border-box",
              }}
              onClick={(e) => {
                e.target.style.boxShadow = "0px 0px 19px 16px rgba(255,255,255,0.5)";
                setTimeout(() => startProcess("male"), 500);
              }}
            ></button>

            <button
              style={{
                borderRadius: "10px",
                backgroundImage: `url(${female})`,
                backgroundSize: "cover",
                backgroundPosition: "center",
                backgroundRepeat: "no-repeat",
                width: "366px",
                height: "438px",
                border: "none",
                cursor: "pointer",
                backgroundColor: "transparent",
                transition: "border 0.3s ease",
                boxSizing: "border-box",
              }}
              onClick={(e) => {
                e.target.style.boxShadow = "0px 0px 19px 16px rgba(255,255,255,0.5)";
                setTimeout(() => startProcess("female"), 500);
              }}
            ></button>
          </div>
        </div>
      )}


      {/* Options Selcet Code  */}
      {isOptions && (
        <div
          style={{
            textAlign: "center",
            width: "100%",
            height: "100%",
            display: "flex",
            flexDirection: "column",
            justifyContent: "flex-end",
            alignItems: "center",
            // backgroundImage: `url(${two})`,
            backgroundRepeat: "no-repeat",
          }}
        >
          <img
            src={two}
            alt=""
            style={{
              width: "100%",
              position: "absolute",
              zIndex: "-100",
            }}
          />
          <div
            style={{
              width: "100%",
              height: "720px",
              display: "flex",
              justifyContent: "flex-start",
            }}
          >
            <button
              style={{
                borderRadius: "10px",
                backgroundImage: `url(${male})`,
                backgroundSize: "cover", // Ensure the image covers the button entirely
                backgroundPosition: "center",
                backgroundRepeat: "no-repeat",
                width: "293px",
                height: "358px",
                border: "none", // Start with no border
                cursor: "pointer",
                backgroundColor: "transparent", // Transparent to show background image
                transition: "border 0.3s ease", // Smooth border transition
                boxSizing: "border-box",
                marginRight: "80px", // Ensures the border is included in the button's size
                marginLeft: "165px", // Ensures the border is included in the button's size
              }}
              onClick={(e) => {
                e.target.style.border = "5px solid #30A6EC"; // Set a visible border on click
                setTimeout(() => startProcess("male"), 500); // Proceed after 500ms
              }}
            ></button>

            <button
              style={{
                borderRadius: "10px",
                backgroundImage: `url(${female})`,
                backgroundSize: "cover",
                backgroundPosition: "center",
                backgroundRepeat: "no-repeat",
                width: "293px", // Adjust width as needed
                height: "358px", // Adjust height as needed
                border: "none",
                cursor: "pointer", // Show pointer cursor on hover
                backgroundColor: "transparent",
                transition: "border 0.3s ease", // Smooth border transition
                boxSizing: "border-box", // Ensures the border is included in the button's size
              }}
              onClick={(e) => {
                e.target.style.border = "5px solid #30A6EC"; // Set a visible border on click
                setTimeout(() => startProcess("female"), 500); // Proceed after 500ms
              }}
            ></button>
          </div>
        </div>
      )}

      {/* Camera Capture Code  */}
      {isCameraOn && (
        <div
          style={{
            textAlign: "center",
            width: "100%",
            height: "100%",
            display: "flex",
            flexDirection: "column",
            justifyContent: "center",
            alignItems: "center",
            backgroundRepeat: "no-repeat",
          }}
        >
          <video
            ref={videoRef}
            autoPlay
            style={{
              display: "block",
              boxShadow: isCameraOn ? "0 1px 10px rgba(0, 0, 0, 0.5)" : "none",
              objectFit: "cover",
              width: "65%",          // wider
              height: "50vh",        // 80% of viewport height
              maxWidth: "1200px",    // allow larger
              maxHeight: "90vh",     // almost full height
            }}
          ></video>


          <canvas ref={canvasRef} style={{ display: "none" }}></canvas>
          <button
            style={{
              width: "380px",
              height: "85px",
              cursor: "pointer",
              border: "none",
              backgroundImage: `url(${captureBg})`,
              backgroundSize: "cover",
              backgroundPosition: "center",
              backgroundRepeat: "no-repeat",
              transition: "opacity 0.3s ease",
              position: "absolute",
              top: "80%",
              textIndent: "-9999px", // hide text but keep accessible
            }}
            onClick={(e) => {
              e.target.style.opacity = "0.8"; // Click feedback
              setTimeout(captureImage, 500);
            }}
          >
          </button>

        </div>
      )}
      {(isGender === "male" || isGender === "female") && (
        <div
          style={{
            display: "flex",
            flexDirection: "column",
            alignItems: "center",
            justifyContent: "center",
            height: "100%",
            perspective: "1200px", // Increased perspective for better 3D effect
          }}
        >
          <h2
            style={{
              color: "#7A4BFF",
              fontSize: "64px",
              fontWeight: "bold",
              letterSpacing: "2px",
              marginTop: "220px",
            }}
          >
            Select your Character
          </h2>



          <div style={carouselContainerStyle}>
            {/* Left Arrow - positioned at center height, left of photos */}
            <button
              onClick={() => handleArrowClick("left")}
              style={{
                fontSize: "32px",
                padding: "20px",
                backgroundColor: "rgba(255, 193, 7, 0.9)",
                border: "3px solid #fff",
                color: "#fff",
                borderRadius: "50%",
                cursor: "pointer",
                transition: "all 0.3s ease",
                boxShadow: "0 5px 15px rgba(0,0,0,0.3)",
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                width: "70px",
                height: "70px",
                position: "absolute",
                left: "-120px", // Position to the left of the photo container
                top: "50%",
                transform: "translateY(-50%)",
                zIndex: 15,
              }}
              onMouseOver={(e) => {
                e.target.style.backgroundColor = "rgba(255, 193, 7, 1)";
                e.target.style.transform = "translateY(-50%) scale(1.1)";
                e.target.style.boxShadow = "0 8px 25px rgba(255, 193, 7, 0.4)";
              }}
              onMouseOut={(e) => {
                e.target.style.backgroundColor = "rgba(255, 193, 7, 0.9)";
                e.target.style.transform = "translateY(-50%) scale(1)";
                e.target.style.boxShadow = "0 5px 15px rgba(0,0,0,0.3)";
              }}
            >
              ◀
            </button>

            {/* Images */}
            {images[isGender].map((imgSrc, i) => (
              <img
                key={i}
                src={imgSrc}
                alt={`Character ${i}`}
                style={getTransformStyle(i)}
                onClick={handleImageClick}
              />
            ))}

            {/* Right Arrow - positioned at center height, right of photos */}
            <button
              onClick={() => handleArrowClick("right")}
              style={{
                fontSize: "32px",
                padding: "20px",
                backgroundColor: "rgba(255, 193, 7, 0.9)",
                border: "3px solid #fff",
                color: "#fff",
                borderRadius: "50%",
                cursor: "pointer",
                transition: "all 0.3s ease",
                boxShadow: "0 5px 15px rgba(0,0,0,0.3)",
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                width: "70px",
                height: "70px",
                position: "absolute",
                right: "-120px", // Position to the right of the photo container
                top: "50%",
                transform: "translateY(-50%)",
                zIndex: 15,
              }}
              onMouseOver={(e) => {
                e.target.style.backgroundColor = "rgba(255, 193, 7, 1)";
                e.target.style.transform = "translateY(-50%) scale(1.1)";
                e.target.style.boxShadow = "0 8px 25px rgba(255, 193, 7, 0.4)";
              }}
              onMouseOut={(e) => {
                e.target.style.backgroundColor = "rgba(255, 193, 7, 0.9)";
                e.target.style.transform = "translateY(-50%) scale(1)";
                e.target.style.boxShadow = "0 5px 15px rgba(0,0,0,0.3)";
              }}
            >
              ▶
            </button>
          </div>

          {/* Left Arrow - positioned at center height, left of photos */}
          <button
            onClick={() => handleArrowClick("left")}
            style={{
              fontSize: "32px",
              padding: "20px",
              backgroundColor: "rgba(255, 193, 7, 0.9)",
              border: "3px solid #fff",
              color: "#fff",
              borderRadius: "50%",
              cursor: "pointer",
              transition: "all 0.3s ease",
              boxShadow: "0 5px 15px rgba(0,0,0,0.3)",
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              width: "70px",
              height: "70px",
              position: "absolute",
              left: "50px", // Position to the left of the photo container
              top: "50%",
              transform: "translateY(-50%)",
              zIndex: 15,
            }}
            onMouseOver={(e) => {
              e.target.style.backgroundColor = "rgba(255, 193, 7, 1)";
              e.target.style.transform = "translateY(-50%) scale(1.1)";
              e.target.style.boxShadow = "0 8px 25px rgba(255, 193, 7, 0.4)";
            }}
            onMouseOut={(e) => {
              e.target.style.backgroundColor = "rgba(255, 193, 7, 0.9)";
              e.target.style.transform = "translateY(-50%) scale(1)";
              e.target.style.boxShadow = "0 5px 15px rgba(0,0,0,0.3)";
            }}
          >
            ◀
          </button>

          {/* Right Arrow - positioned at center height, right of photos */}
          <button
            onClick={() => handleArrowClick("right")}
            style={{
              fontSize: "32px",
              padding: "20px",
              backgroundColor: "rgba(255, 193, 7, 0.9)",
              border: "3px solid #fff",
              color: "#fff",
              borderRadius: "50%",
              cursor: "pointer",
              transition: "all 0.3s ease",
              boxShadow: "0 5px 15px rgba(0,0,0,0.3)",
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              width: "70px",
              height: "70px",
              position: "absolute",
              right: "50px", // Position to the right of the photo container
              top: "50%",
              transform: "translateY(-50%)",
              zIndex: 15,
            }}
            onMouseOver={(e) => {
              e.target.style.backgroundColor = "rgba(255, 193, 7, 1)";
              e.target.style.transform = "translateY(-50%) scale(1.1)";
              e.target.style.boxShadow = "0 8px 25px rgba(255, 193, 7, 0.4)";
            }}
            onMouseOut={(e) => {
              e.target.style.backgroundColor = "rgba(255, 193, 7, 0.9)";
              e.target.style.transform = "translateY(-50%) scale(1)";
              e.target.style.boxShadow = "0 5px 15px rgba(0,0,0,0.3)";
            }}
          >
            ▶
          </button>

          <div style={{ marginTop: "25px", display: "flex", gap: "12px", alignItems: "center" }}>
            <span style={{ color: "#fff", fontSize: "14px", marginRight: "10px" }}>
              {currentIndex + 1} of {images[isGender].length}
            </span>
            {images[isGender].map((_, i) => (
              <div
                key={i}
                style={{
                  width: i === currentIndex ? "16px" : "12px",
                  height: i === currentIndex ? "16px" : "12px",
                  borderRadius: "50%",
                  backgroundColor: i === currentIndex ? "#30A6EC" : "rgba(255,255,255,0.5)",
                  cursor: "pointer",
                  transition: "all 0.3s ease",
                  border: i === currentIndex ? "2px solid #fff" : "1px solid rgba(255,255,255,0.3)",
                  boxShadow: i === currentIndex ? "0 0 10px rgba(48, 166, 236, 0.6)" : "none",
                }}
                onClick={() => setCurrentIndex(i)}
                onMouseOver={(e) => {
                  if (i !== currentIndex) {
                    e.target.style.backgroundColor = "rgba(255,255,255,0.8)";
                    e.target.style.transform = "scale(1.2)";
                  }
                }}
                onMouseOut={(e) => {
                  if (i !== currentIndex) {
                    e.target.style.backgroundColor = "rgba(255,255,255,0.5)";
                    e.target.style.transform = "scale(1)";
                  }
                }}
              />
            ))}
          </div>
        </div>
      )}
    </section>

  );
}

export default Camer;