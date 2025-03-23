
export const formatDate = (dateStr)  =>{
    const date = new Date(dateStr);
  
    // Format the date to a more human-readable format
    return date.toLocaleString('en-US', {
      weekday: 'long',   // e.g. "Monday"
      year: 'numeric',   // e.g. "2025"
      month: 'long',     // e.g. "January"
      day: 'numeric',    // e.g. "16"
      hour: 'numeric',   // e.g. "1"
      minute: 'numeric', // e.g. "11"
      second: 'numeric', // e.g. "35"
      hour12: true       // Use 12-hour format with AM/PM
    });
  }

export const formatAge = (creationTimestamp) => {
  const created = new Date(creationTimestamp);
  const now = new Date();
  const diffMs = now - created;
  const diffDays = Math.floor(diffMs / (1000 * 60 * 60 * 24));
  
  if (diffDays > 0) {
    return `${diffDays}d`;
  }
  
  const diffHrs = Math.floor(diffMs / (1000 * 60 * 60));
  if (diffHrs > 0) {
    return `${diffHrs}h`;
  }
  
  const diffMins = Math.floor(diffMs / (1000 * 60));
  return `${diffMins}m`;
};


