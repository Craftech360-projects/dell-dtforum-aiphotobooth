import React, { useState, useEffect } from "react";
import { supabase } from "./supabaseClient";
import JSZip from "jszip";
import FileSaver from "file-saver";
import "./Admin.css"; // Import CSS for styling

const Admin = () => {
  const [folders, setFolders] = useState([]);
  const [loading, setLoading] = useState(false);
  const [errorMessage, setErrorMessage] = useState(null);
  const bucketName = "test-bucket"; // Fixed bucket name

  // Fetch folders inside the test-bucket
  useEffect(() => {
    const fetchFolders = async () => {
      setLoading(true);
      console.log("Fetching folders...");

      const { data: folderData, error } = await supabase.storage
        .from(bucketName)
        .list("");

      if (error) {
        setErrorMessage(
          `Error fetching folders from ${bucketName}: ${error.message}`
        );
        console.error("Error fetching folders:", error);
      } else {
        const foldersWithCount = await Promise.all(
          folderData.map(async (folder) => {
            const { data: fileData, error: fileError } = await supabase.storage
              .from(bucketName)
              .list(folder.name); // Get files in the folder
            console.log("fileData",fileData);
            
            if (fileError) {
              console.error(
                `Error fetching files for folder ${folder.name}:`,
                fileError
              );
              return { name: folder.name, fileCount: 0 }; // Return 0 if there's an error
            }

            return { name: folder.name, fileCount: fileData.length }; // Count files in the folder
          })
        );

        console.log("Fetched Folders:", foldersWithCount); // Log fetched folders with file count
        setFolders(foldersWithCount);
      }
      setLoading(false);
    };

    fetchFolders();
  }, [bucketName]);

  // Function to download all images in a folder as a ZIP file
  const handleFolderClick = async (folderName) => {
    console.log(`Folder clicked: ${folderName}`); // Log folder click
    setLoading(true); // Start loading animation

    // Fetch images from the folder
    const { data: imageData, error } = await supabase.storage
      .from(bucketName)
      .list(folderName, { limit: 1000 }); // Increased limit to ensure we can fetch all images

    if (error) {
      setErrorMessage(
        `Error fetching images from folder ${folderName}: ${error.message}`
      );
      console.error("Error fetching images:", error);
      setLoading(false);
      return;
    }

    // Create ZIP file
    const zip = new JSZip();
    const folder = zip.folder(folderName); // Create a folder in the ZIP

    // Fetch and add each image to the ZIP
    const imageFetchPromises = imageData.map(async (image) => {
      const fileName = `${folderName}/${image.name}`;
      const url = `https://aimistcqlndneimalstl.supabase.co/storage/v1/object/public/test-bucket/${fileName}`;
      const response = await fetch(url);
      const blob = await response.blob();
      folder.file(image.name, blob); // Add file to ZIP
    });

    // Wait for all images to be fetched and added to the ZIP
    await Promise.all(imageFetchPromises);

    // Generate ZIP and download
    zip.generateAsync({ type: "blob" }).then((content) => {
      FileSaver.saveAs(content, `${folderName}.zip`);
      setLoading(false); // Stop loading animation
    });
  };

  return (
    <div className="admin-panel">
      <h1>Admin Dashboard - Test Bucket</h1>
      {loading && <div className="loader"></div>} {/* Show loading animation */}
      {errorMessage && <p style={{ color: "red" }}>{errorMessage}</p>}
      {/* Folders Table */}
      {loading == false && (
        <div className="folder-section">
          <h3>Folders in {bucketName}</h3>
          {folders.length > 0 ? (
            <table className="folder-table">
              <thead>
                <tr>
                  <th>Folder Name</th>
                  {/* <th>Number of Files</th> */}
                  <th>Download</th>
                </tr>
              </thead>
              <tbody>
                {folders.map((folder) => (
                  <tr key={folder.name}>
                    <td>{folder.name}</td>
                    {/* <td>{folder.fileCount} files</td> */}
                    <td>
                      <button
                        onClick={() => handleFolderClick(folder.name)}
                        className="download-button"
                        disabled={loading} // Disable button while loading
                      >
                        Download
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          ) : (
            <p>No folders found in this bucket.</p>
          )}
        </div>
      )}
    </div>
  );
};

export default Admin;
