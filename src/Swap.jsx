import QRCode from "qrcode.react";
import React, { forwardRef, useEffect, useRef, useState } from "react";
import { useLocation, useNavigate } from "react-router-dom";
import styled, { keyframes } from "styled-components";
import { supabase } from "./supabaseClient";
import bg2 from "/bg2.png";
import home from "/assets/home.png";

// --- Styled Spinner ---
const spin = keyframes`
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
`;

const Spinner = styled.div`
  border: 12px solid rgba(255, 255, 255, 0.2);
  border-left-color: #7A4BFF;
  border-right-color: #4FCFFB;
  border-radius: 50%;
  width: 120px;
  height: 120px;
  animation: ${spin} 1s linear infinite;
`;

function Swap() {
  const navigate = useNavigate();
  const location = useLocation();

  const sourceImageBlob = location.state?.sourceImage;
  const selectedImage = location.state?.isImg;
  const userDetails = location.state?.userDetails;

  const [loading, setLoading] = useState(true);
  const [resultImageUrl, setResultImageUrl] = useState(null);
  const [hasRun, setHasRun] = useState(false);
  const printRef = useRef();

  useEffect(() => {
    if (hasRun || !sourceImageBlob || !selectedImage || !userDetails) {
      if (!sourceImageBlob || !selectedImage || !userDetails) {
        console.error("Incomplete data passed to Swap component. Redirecting home.");
        navigate("/");
      }
      return;
    }

    const processAndSaveData = async () => {
      setHasRun(true);
      try {
        const sourceFileName = `source-images/${Date.now()}-source.jpg`;
        const { error: sourceUploadError } = await supabase.storage
          .from("images")
          .upload(sourceFileName, sourceImageBlob, {
            contentType: "image/jpeg",
            upsert: false,
          });

        if (sourceUploadError) throw new Error(`Source image upload failed: ${sourceUploadError.message}`);

        const { data: { publicUrl: src_image_url } } = supabase.storage.from('images').getPublicUrl(sourceFileName);
        if (!src_image_url) throw new Error("Failed to get public URL for source image.");

        const targetImageResponse = await fetch(selectedImage);
        if (!targetImageResponse.ok) throw new Error(`Failed to fetch target image: ${targetImageResponse.statusText}`);
        const targetImageBlob = await targetImageResponse.blob();

        const formData = new FormData();
        formData.append("sourceImage", new File([sourceImageBlob], "source.jpg", { type: "image/jpeg" }));
        formData.append("targetImage", new File([targetImageBlob], "target.jpg", { type: "image/jpeg" }));
        formData.append("name", userDetails.name);
        formData.append("email", userDetails.email);

        const swapResponse = await fetch("https://90973e4d3afa.ngrok-free.app/api/swap-face/", {
          method: "POST",
          body: formData,
        });

        if (!swapResponse.ok) {
          const errorData = await swapResponse.json();
          throw new Error(errorData.detail || "Face swap API call failed");
        }

        const swappedImageBlob = await swapResponse.blob();
        const resultFileName = `swapped-images/${Date.now()}-result.jpg`;
        const { error: resultUploadError } = await supabase.storage
          .from("images")
          .upload(resultFileName, swappedImageBlob, {
            contentType: "image/jpeg",
            upsert: false,
          });

        if (resultUploadError) throw new Error(`Result image upload failed: ${resultUploadError.message}`);

        const { data: { publicUrl: trg_image_url } } = supabase.storage.from('images').getPublicUrl(resultFileName);
        if (!trg_image_url) throw new Error("Failed to get public URL for result image.");

        const { error: insertError } = await supabase
          .from("photobooth_data")
          .insert([{ name: userDetails.name, email: userDetails.email, src_image_url, trg_image_url }]);

        if (insertError) throw new Error(`Database insert failed: ${insertError.message}`);

        setResultImageUrl(trg_image_url);
      } catch (error) {
        console.error("An error occurred during the process:", error);
        navigate("/error");
      } finally {
        setLoading(false);
      }
    };

    processAndSaveData();
  }, [hasRun, sourceImageBlob, selectedImage, userDetails, navigate]);

  const LoadingAnimation = () => (
    <div style={{
      display: "flex",
      justifyContent: "center",
      alignItems: "center",
      height: "100%",
      width: "100%",
    }}>
      <Spinner />
    </div>
  );

  const ResultDisplay = () => {
    const [imageLoaded, setImageLoaded] = useState(false);

    useEffect(() => {
      if (resultImageUrl) {
        const img = new Image();
        img.onload = () => setImageLoaded(true);
        img.src = resultImageUrl;
      }
    }, [resultImageUrl]);

    const goHome = () => navigate("/");

    return (
      <div style={{
        width: "100%",
        height: "100%",
        display: "flex",
        justifyContent: "center",
        alignItems: "center",
        padding: "2rem"
      }}>
        {imageLoaded && (
          <div style={{
            display: "flex",
            flexDirection: "column",
            justifyContent: "center",
            alignItems: "center",
            gap: "1.5rem",
            maxWidth: "1200px",
            marginTop: '326px'
          }}>
            {/* Image */}
            <img
              src={resultImageUrl}
              alt="Swapped Result"
              style={{
                width: "60%",
                height: "auto",
                objectFit: "cover",
                borderRadius: "16px",
                border: "8px solid #30A6EC",
              }}
            />

            {/* QR + Button Row */}
            <div style={{
              display: "flex",
              flexDirection: "row",
              alignItems: "center",
              justifyContent: "center",
              gap: "2rem",
              marginBottom: "1rem"
            }}>
              {/* QR Code */}
              <div style={{
                padding: "20px",
                backgroundColor: "#fff",
                borderRadius: "24px",
                border: "8px solid #4FCFFB"
              }}>
                <QRCode value={resultImageUrl} size={250} />
              </div>

              {/* Home Button with Text */}
              <div style={{
                display: "flex",
                flexDirection: "column",
                alignItems: "center",
                justifyContent: "center",
              }}>
                <p style={{
                  fontSize: "40px",
                  fontWeight: "800",
                  color: "#7A4BFF",
                  marginBottom: "12px",
                  textAlign: "center",
                  width: '413px'
                }}>
                  Scan the QR code <br />to download the image
                </p>
                <button
                  style={{
                    width: "240px",
                    height: "60px",
                    cursor: "pointer",
                    border: "none",
                    backgroundColor: "transparent",
                    backgroundImage: `url(${home})`,
                    backgroundSize: "contain",
                    backgroundPosition: "center",
                    backgroundRepeat: "no-repeat",
                    transition: "transform 0.2s ease",
                  }}
                  onClick={goHome}
                  onMouseOver={(e) => (e.target.style.transform = "scale(1.1)")}
                  onMouseOut={(e) => (e.target.style.transform = "scale(1)")}
                />
              </div>
            </div>
          </div>
        )}
      </div>
    );
  };

  return (
    <div style={{
      width: "100vw",
      height: "100vh",
      backgroundImage: `url(${bg2})`,
      backgroundSize: "cover",
      backgroundPosition: "center",
      backgroundRepeat: "no-repeat",
    }}>
      {loading ? <LoadingAnimation /> : <ResultDisplay />}
    </div>
  );
}

export default Swap;
