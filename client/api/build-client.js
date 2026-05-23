import axios from 'axios';

export default ({ req }) => {
  if (typeof window === 'undefined') {
    // Server side - route through ingress nginx internal hostname
    return axios.create({
      baseURL: 'http://ingress-nginx-controller.ingress-nginx.svc.cluster.local',
      headers: req.headers,
    });
  } else {
    // Browser side - go through ingress
    return axios.create({
      baseURL: '/',
    });
  }
};