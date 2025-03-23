export const truncateText = (text, maxLength = 45) => {
    if (!text) return '';
    if (text.length <= maxLength) return text;
    return `${text.substring(0, maxLength)}...`;
};


export const getActivityTypeColor = (type) => {
    switch (type) {
        case 'Normal':
            return 'success';
        case 'Warning':
            return 'warning';
        case 'Info':
            return 'info';
        default:
            return 'primary';
    }
};


export const getStatusColor = (status) => {

    const statusMap = {
        'Running': 'success',
        'Succeeded': 'success',
        'Pending': 'warning',
        'Failed': 'warning',
        'Unknown': 'warning',
        'CrashLoopBackOff': 'warning',
        'Error': 'warning',
        'Terminating': 'warning',
        'Completed': 'success'
    };

    return statusMap[status] || 'warning';
};
