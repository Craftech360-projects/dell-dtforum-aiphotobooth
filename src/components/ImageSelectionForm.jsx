import React, { useState } from "react";
import imageData from "../assets/test.json"; // Adjust the import path as necessary
import captureImageIcon from "/assets/pmagic.png"; // Import the PNG imag
import m1 from "/assets/Male 01.jpg"; // Import the PNG imag
import m2 from "/assets/Male 02.jpg"; // Import the PNG imag
import f1 from "/assets/Female 01.jpg"; // Import the PNG imag
import f2 from "/assets/Female 02.jpg"; // Import the PNG imag
const ImageSelectionForm = ({ selectImage, handleSubmit, setIsGender }) => {
  const [selectedImage, setSelectedImage] = useState(null);
  const [isSelected, setIsSelected] = useState(false);
  console.log(setIsGender, "setIsGender");
  // selectImage(`f1.jpg`);
  // Conditionally select images based on the gender
  const isMale = setIsGender === "male";
  const image1 = isMale ? m1 : f1; // Assign m1 for male, f1 for female
  const image2 = isMale ? m2 : f2; // Assign m2 for male, f2 for female
  console.log(image1, image2);

  return (
    <div
      style={{
        width: "100vw",
        height: "100vh",
        display: "flex",
        flexDirection: "column",
        justifyContent: "flex-start",
        alignItems: "center",
        paddingTop: "800px",
      }}
    >
      {setIsGender === "male" && (
        <>
          <img
            src={image1}
            alt="Swapped Result"
            style={{
              width: "70%",
              objectFit: "cover",
              justifyContent: "center",
              alignItems: "center",
              borderRadius: "16px",
              marginBottom: "42px",
              cursor: "pointer",
            }}
            onClick={(e) => {
              e.target.style.border = "8px solid #30A6EC"; // Change background
              selectImage(`Male 01.jpg`);
              setTimeout(() => {
                setIsSelected(true);
              }, 500); // Wait 50ms then proceed
            }}
          />

          <img
            src={image2}
            alt="Swapped Result"
            style={{
              width: "70%",
              objectFit: "cover",
              justifyContent: "center",
              alignItems: "center",
              borderRadius: "16px",
              cursor: "pointer",
            }}
            onClick={(e) => {
              e.target.style.border = "8px solid #30A6EC"; // Change background
              selectImage(`Male 02.jpg`);
              setTimeout(() => {
                setIsSelected(true);
              }, 500); // Wait 50ms then proceed
            }}
          />
        </>
      )}

      {setIsGender === "female" && (
        <>
          <img
            src={image1}
            alt="Swapped Result"
            style={{
              width: "70%",
              objectFit: "cover",
              justifyContent: "center",
              alignItems: "center",
              borderRadius: "16px",
              marginBottom: "42px",
              cursor: "pointer",
            }}
            onClick={(e) => {
              e.target.style.border = "8px solid #30A6EC"; // Change background
              selectImage(`Femal 02.jpg`);
              setTimeout(() => {
                setIsSelected(true);
              }, 500); // Wait 50ms then proceed
            }}
          />

          <img
            src={image2}
            alt="Swapped Result"
            style={{
              width: "70%",
              objectFit: "cover",
              justifyContent: "center",
              alignItems: "center",
              borderRadius: "16px",
              cursor: "pointer",
            }}
            onClick={(e) => {
              e.target.style.border = "8px solid #30A6EC"; // Change background
              selectImage(`Female 01.jpg`);
              setTimeout(() => {
                setIsSelected(true);
              }, 500); // Wait 50ms then proceed
            }}
          />
        </>
      )}

      {isSelected && (
        <button
          type="submit"
          style={{
            width: "350px",
            height: "120px",
            cursor: "pointer",
            bottom: "15%",
            left: "32%",
            position: "absolute",
            borderRadius: "10px",
            border: "none",
            fontSize: "48px",
            fontWeight: "bold",
            backgroundColor: "#ffffff", // Default color
            color: "#000000", // Default text color
            transition: "background-color 0.3s ease, color 0.3s ease",
          }}
          onClick={(e) => {
            e.target.style.backgroundColor = "#30A6EC"; // Change background
            e.target.style.color = "#ffffff"; // Change text color
            setTimeout(() => {
              e.preventDefault(); // Prevent default form submission if needed
              handleSubmit(e); // Pass event to handleSubmit
            }, 1000); // Wait 50ms then proceed
          }}
        >
          Generate
        </button>
      )}
    </div>
  );
};

export default ImageSelectionForm;
