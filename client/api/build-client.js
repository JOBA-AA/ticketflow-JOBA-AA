import axios from 'axios';

export default ({ req }) => {
  if (typeof window === 'undefined') {
    // We are on the server - use internal service routing
    const baseURL = process.env.API_URL || 
      'http://ingress-nginx-controller.ingress-nginx.svc.cluster.local';
    
    return axios.create({
      baseURL,
      headers: req.headers,
    });
  } else {
    // We must be on the browser
    return axios.create({
      baseURL: '/',
    });
  }
};