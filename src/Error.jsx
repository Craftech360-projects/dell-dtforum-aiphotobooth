// eslint-disable-next-line no-unused-vars
import React from 'react';
import { useLocation, useNavigate } from "react-router-dom";
function Error() {
    const navigate = useNavigate();
  return (
    <div style={{
        width: "100vw",
        height: "100vh",
        display: "flex",
        flexDirection:'column',
        justifyContent: "center",
        alignItems: "center",
      }}>
     <div style={{textAlign:'center', padding:'30px',backgroundColor:'#f20c3f'}}>
     <h1 >Error something went wrong!</h1>
     <button style={{backgroundColor:'black', color:'white', padding:'10px 25px', border:'none',borderRadius:'5px'}} onClick={()=> navigate("/") }>GO HOME</button>
     </div>
    </div>
  );
}

export default Error;
