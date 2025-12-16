const supabase = require('../config/supabase');

const getPosts = async (postType, limit, offset) => {
    let query = supabase.from('posts').select(`
        *,
        user:profiles!userId(*),
        comments:comments(*),
        likes:likes(*)
    `).order('created_at', { ascending: false });

    if (postType) {
        query = query.eq('post_type', postType);
    }

    if (limit) {
        query = query.limit(limit);
    }

    if (offset) {
        query = query.range(offset, offset + limit - 1);
    }

    const { data, error } = await query;
    if (error) throw new Error(error.message);
    return data;
};

const createPost = async (postData, userId) => {
    const { caption, imageUrl, postType } = postData;
    const { data, error } = await supabase.from('posts').insert([{ caption, image_url: imageUrl, post_type: postType, userId }]).select();
    if (error) throw new Error(error.message);
    return data[0];
};

const getUserPosts = async (userId, postType) => {
    let query = supabase.from('posts').select(`
        *,
        user:profiles!userId(*),
        comments:comments(*),
        likes:likes(*)
    `).eq('userId', userId).order('created_at', { ascending: false });

    if (postType) {
        query = query.eq('post_type', postType);
    }

    const { data, error } = await query;
    if (error) throw new Error(error.message);
    return data;
};

const toggleLike = async (postId, userId) => {
    const { data: existingLike, error: likeError } = await supabase.from('likes').select('*').eq('post_id', postId).eq('user_id', userId).single();

    if (likeError && likeError.code !== 'PGRST116') { // PGRST116: no rows found
        throw new Error(likeError.message);
    }

    if (existingLike) {
        const { error: deleteError } = await supabase.from('likes').delete().match({ post_id: postId, user_id: userId });
        if (deleteError) throw new Error(deleteError.message);
        return { liked: false };
    } else {
        const { error: insertError } = await supabase.from('likes').insert([{ post_id: postId, user_id: userId }]);
        if (insertError) throw new Error(insertError.message);
        return { liked: true };
    }
};

const addComment = async (postId, commentData, userId) => {
    const { comment } = commentData;
    const { data, error } = await supabase.from('comments').insert([{ post_id: postId, user_id: userId, comment }]).select();
    if (error) throw new Error(error.message);
    return data[0];
};

const getComments = async (postId) => {
    const { data, error } = await supabase.from('comments').select('*').eq('post_id', postId).order('created_at', { ascending: false });
    if (error) throw new Error(error.message);
    return data;
};

const deletePost = async (postId, userId) => {
    const { error } = await supabase.from('posts').delete().match({ id: postId, userId });
    if (error) throw new Error(error.message);
};

module.exports = {
    getPosts,
    createPost,
    getUserPosts,
    toggleLike,
    addComment,
    getComments,
    deletePost
};